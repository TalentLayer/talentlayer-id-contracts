// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {ERC721A} from "./libs/ERC721A.sol";
import {IProofOfHumanity} from "./interfaces/IProofOfHumanity.sol";
import {ITalentLayerPlatformID} from "./interfaces/ITalentLayerPlatformID.sol";

/**
 * @title TalentLayer ID Contract
 * @author TalentLayer Team @ ETHCC22 Hackathon
 */
contract TalentLayerID is ERC721A, Ownable {
    // =========================== Structs ==============================

    /// @notice TalentLayer Profile information struct
    /// @param profileId the talentLayerId of the profile
    /// @param handle the handle of the profile
    /// @param pohAddress the proof of humanity address of the profile
    /// @param platformId the TalentLayer Platform Id linked to the profile
    /// @param dataUri the IPFS URI of the profile metadata
    struct Profile {
        uint256 id;
        string handle;
        address pohAddress;
        uint256 platformId;
        string dataUri;
    }

    // =========================== Mappings ==============================

    /// Proof of Humanity registry
    IProofOfHumanity public pohRegistry;

    /// TalentLayer Platform ID registry
    ITalentLayerPlatformID public talentLayerPlatformIdContract;

    /// Taken handles
    mapping(string => bool) public takenHandles;

    /// Token ID to Profile struct
    mapping(uint256 => Profile) public profiles;

    /// Account recovery merkle root
    bytes32 public recoveryRoot;

    /// Addresses that have successfully recovered their account
    mapping(address => bool) public hasBeenRecovered;

    /// Price to mint an id (in wei, upgradable)
    uint256 public mintFee;

    /**
     * @param _pohAddress Proof of Humanity registry address
     */
    constructor(address _pohAddress, address _talentLayerPlatformIdAddress) ERC721A("TalentLayerID", "TID") {
        pohRegistry = IProofOfHumanity(_pohAddress);
        talentLayerPlatformIdContract = ITalentLayerPlatformID(_talentLayerPlatformIdAddress);
        mintFee = 0;
    }

    // =========================== View functions ==============================

    /**
     * Allows retrieval of number of minted TalentLayerIDs for a user.
     * @param _user Address of the owner of the TalentLayerID
     * @return the number of tokens minted by the user
     */
    function numberMinted(address _user) public view returns (uint256) {
        return balanceOf(_user);
    }

    function getProfile(uint256 _profileId) external view returns (Profile memory) {
        require(_exists(_profileId), "TalentLayerID: Profile does not exist");
        return profiles[_profileId];
    }

    /**
     * Allows checking if Proof of Humanity address linked to the TalentLayerID is registered.
     * @param _tokenId Token ID to check
     * @return true if Proof of Humanity address is registered, false otherwise
     */
    function isTokenPohRegistered(uint256 _tokenId) public view returns (bool) {
        return pohRegistry.isRegistered(profiles[_tokenId].pohAddress);
    }

    /**
     * Allows getting the TalentLayerID of one address
     * @param _owner Address to check
     * @return uint256 the id of the NFT
     */
    function walletOfOwner(address _owner) public view returns (uint256) {
        uint256 ownedTokenId;
        uint256 currentTokenId = _startTokenId();
        address latestOwnerAddress;

        while (currentTokenId <= totalSupply()) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenId = currentTokenId;
                break;
            }

            currentTokenId++;
        }

        return ownedTokenId;
    }

    /**
     * @notice Returns the platform ID of the platform which onboarded the user.
     * @param _address The address of the user
     */
    function getOriginatorPlatformIdByAddress(address _address) external view returns (uint256) {
        return profiles[walletOfOwner(_address)].platformId;
    }

    /**
     * @notice Check whether the User Token Id is valid.
     * @param _tokenId Token ID to check
     */
    function isValid(uint256 _tokenId) external view {
        require(_tokenId > 0 && _tokenId <= totalSupply(), "Your ID is not a valid token ID");
    }

    // =========================== User functions ==============================

    /**
     * Allows a user to mint a new TalentLayerID without the need of Proof of Humanity.
     * @param _handle Handle for the user
     * @param _platformId Platform ID from which UserId wad minted
     */
    function mint(uint256 _platformId, string memory _handle) public payable canPayAndMint(msg.sender, _handle, _platformId) {
        _safeMint(msg.sender, 1);
        _afterMint(msg.sender, _handle, false, _platformId, msg.value);
    }

    /**
     * Allows a user to mint a new TalentLayerID with Proof of Humanity.
     * @param _handle Handle for the user
     * @param _platformId Platform ID from which UserId minted
     */
    function mintWithPoh(uint256 _platformId, string memory _handle) public payable canPayAndMint(msg.sender, _handle, _platformId) {
        require(pohRegistry.isRegistered(msg.sender), "You need to use an address registered on Proof of Humanity");
        _safeMint(msg.sender, 1);
        uint256 userTokenId = _nextTokenId() - 1;
        profiles[userTokenId].pohAddress = msg.sender;
        _afterMint(msg.sender, _handle, true, _platformId, msg.value);
    }

    /**
     * Link Proof of Humanity to previously non-linked TalentLayerID.
     * @param _tokenId Token ID to link
     */
    function activatePoh(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(pohRegistry.isRegistered(msg.sender), "You're address is not registerd for poh");
        profiles[_tokenId].pohAddress = msg.sender;

        emit PohActivated(msg.sender, _tokenId, profiles[_tokenId].handle);
    }

    /**
     * Update user data.
     * @dev we are trusting the user to provide the valid IPFS URI (changing in v2)
     * @param _tokenId Token ID to update
     * @param _newCid New IPFS URI
     */
    function updateProfileData(uint256 _tokenId, string memory _newCid) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(bytes(_newCid).length > 0, "Should provide a valid IPFS URI");
        profiles[_tokenId].dataUri = _newCid;

        emit CidUpdated(_tokenId, _newCid);
    }

    /**
     * Allows recovery of a user's account with zero knowledge proofs.
     * @param _oldAddress Old user address
     * @param _tokenId Token ID to recover
     * @param _index Index in the merkle tree
     * @param _recoveryKey Recovery key
     * @param _handle User handle
     * @param _merkleProof Merkle proof
     */
    function recoverAccount(
        address _oldAddress,
        uint256 _tokenId,
        uint256 _index,
        uint256 _recoveryKey,
        string calldata _handle,
        bytes32[] calldata _merkleProof
    ) public {
        require(!hasBeenRecovered[_oldAddress], "This address has already been recovered");
        require(ownerOf(_tokenId) == _oldAddress, "You are not the owner of this token");
        require(numberMinted(msg.sender) == 0, "You already have a token");
        require(profiles[_tokenId].pohAddress == address(0), "Your old address was not linked to Proof of Humanity");
        require(
            keccak256(abi.encodePacked(profiles[_tokenId].handle)) == keccak256(abi.encodePacked(_handle)),
            "Invalid handle"
        );
        require(pohRegistry.isRegistered(msg.sender), "You need to use an address registered on Proof of Humanity");

        bytes32 node = keccak256(abi.encodePacked(_index, _recoveryKey, _handle, _oldAddress));
        require(MerkleProof.verify(_merkleProof, recoveryRoot, node), "MerkleDistributor: Invalid proof.");

        hasBeenRecovered[_oldAddress] = true;
        profiles[_tokenId].handle = _handle;
        profiles[_tokenId].pohAddress = msg.sender;
        _internalTransferFrom(_oldAddress, msg.sender, _tokenId);

        emit AccountRecovered(msg.sender, _oldAddress, _handle, _tokenId);
    }

    // =========================== Owner functions ==============================

    /**
     * Set new TalentLayer ID recovery root.
     * @param _newRoot New merkle root
     */
    function updateRecoveryRoot(bytes32 _newRoot) public onlyOwner {
        recoveryRoot = _newRoot;
    }

    /**
     * Updates the mint fee.
     * @param _mintFee The new mint fee
     */
    function updateMintFee(uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
        emit MintFeeUpdated(_mintFee);
    }

    /**
     * Withdraws the contract balance to the owner.
     */
    function withdraw() public onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to withdraw Ether");
    }

    /**
     * Allows a user to mint a new TalentLayerID for free without the need of Proof of Humanity.
     * @param _handle Handle for the user
     * @param _platformId Platform ID from which UserId wad minted
     */
    function freeMint(uint256 _platformId, address _userAddress, string memory _handle) public canMint(_userAddress, _handle, _platformId) onlyOwner{
        _safeMint(_userAddress, 1);
        _afterMint(_userAddress, _handle, false, _platformId, 0);
    }

    /**
     * Allows the contract owner to mint a new TalentLayerID for free with Proof of Humanity.
     * @param _handle Handle for the user
     * @param _platformId Platform ID from which UserId minted
     */
    function freeMintWithPoh(uint256 _platformId, address _userAddress, string memory _handle) public canMint(_userAddress, _handle, _platformId) onlyOwner{
        require(pohRegistry.isRegistered(_userAddress), "You need to use an address registered on Proof of Humanity");
        _safeMint(_userAddress, 1);
        uint256 userTokenId = _nextTokenId() - 1;
        profiles[userTokenId].pohAddress = _userAddress;
        _afterMint(_userAddress, _handle, true, _platformId, 0);
    }

    // =========================== Private functions ==============================

    /**
     * Update handle address mapping and emit event after mint.
     * @param _handle Handle for the user
     * @param _platformId Platform ID from which UserId wad minted
     */
    function _afterMint(
        address _userAddress,
        string memory _handle,
        bool _poh,
        uint256 _platformId,
        uint256 _fee
    ) private {
        uint256 userTokenId = _nextTokenId() - 1;
        Profile storage profile = profiles[userTokenId];
        profile.platformId = _platformId;
        profile.handle = _handle;
        takenHandles[_handle] = true;

        emit Mint(_userAddress, userTokenId, _handle, _poh, _platformId, _fee);
    }

    /**
     * Checks making sure that a the arguments are meeting the requirements for minting a TalentLayerID
     * @param _userAddress the address of the user to mint the TalentLayer ID for.
     * @param _handle the Handle of the user with to mint the TalentLayer ID for.
     * @param _platformId The ID of the platform that mints the TalentLayer ID.
     */
    function _canMint(
        address _userAddress, 
        string memory _handle, 
        uint256 _platformId
    ) private {
        require(numberMinted(_userAddress) == 0, "You already have a TalentLayerID");
        require(bytes(_handle).length >= 2, "Handle too short");
        require(bytes(_handle).length <= 10, "Handle too long");
        require(!takenHandles[_handle], "Handle already taken");
        talentLayerPlatformIdContract.isValid(_platformId);
    }

    /**
     * Checks that enough funds have been sent for paying the fees for minting a TalentLayerID. 
     */
    function _canPay() private view {
        require(msg.value == mintFee, "Incorrect amount of ETH for mint fee");
    }

    // =========================== Internal functions ==============================

    /**
     * Update the start token id to 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =========================== Overrides ==============================

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {}

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        return _buildTokenURI(tokenId);
    }

    function _buildTokenURI(uint256 id) internal view returns (string memory) {
        string memory username = profiles[id].handle;

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 720"><defs><linearGradient id="a" x1="67.94" y1="169.48" x2="670.98" y2="562.86" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#17a9c2"/><stop offset=".12" stop-color="#1aa9bc"/><stop offset=".29" stop-color="#25abab"/><stop offset=".48" stop-color="#35ad8f"/><stop offset=".64" stop-color="#48b072"/><stop offset=".78" stop-color="#59b254"/><stop offset="1" stop-color="#7ab720"/></linearGradient></defs><path style="fill:url(#a)" d="M0 0h720v720H0z"/><path d="M47.05 92.37V53.84H33.29V46h36.85v7.84H56.41v38.52h-9.36Zm35.71-23.34-8.07-1.46c.91-3.25 2.47-5.65 4.68-7.21 2.21-1.56 5.5-2.34 9.87-2.34 3.96 0 6.92.47 8.86 1.41 1.94.94 3.31 2.13 4.1 3.57s1.19 4.1 1.19 7.96l-.1 10.37c0 2.95.14 5.13.43 6.53.28 1.4.82 2.91 1.6 4.51h-8.79c-.23-.59-.52-1.47-.85-2.63-.15-.53-.25-.88-.32-1.04-1.52 1.48-3.14 2.58-4.87 3.32s-3.57 1.11-5.54 1.11c-3.46 0-6.18-.94-8.18-2.82-1.99-1.88-2.99-4.25-2.99-7.12 0-1.9.45-3.59 1.36-5.08s2.18-2.63 3.81-3.42 3.99-1.48 7.07-2.07c4.15-.78 7.03-1.51 8.63-2.18v-.89c0-1.71-.42-2.93-1.27-3.65s-2.44-1.09-4.78-1.09c-1.58 0-2.82.31-3.7.93-.89.62-1.6 1.71-2.15 3.27Zm11.89 7.21c-1.14.38-2.94.83-5.41 1.36-2.47.53-4.08 1.04-4.84 1.55-1.16.82-1.74 1.87-1.74 3.13s.46 2.32 1.39 3.23c.93.91 2.11 1.36 3.54 1.36 1.6 0 3.13-.53 4.59-1.58 1.08-.8 1.78-1.78 2.12-2.94.23-.76.35-2.2.35-4.33v-1.77Zm17.49 16.13V46h8.89v46.37h-8.89Zm37.45-10.69 8.86 1.49c-1.14 3.25-2.94 5.72-5.39 7.42s-5.53 2.55-9.22 2.55c-5.84 0-10.16-1.91-12.97-5.72-2.21-3.06-3.32-6.92-3.32-11.58 0-5.57 1.46-9.93 4.36-13.08 2.91-3.15 6.59-4.73 11.04-4.73 5 0 8.94 1.65 11.83 4.95s4.27 8.36 4.14 15.17h-22.27c.06 2.64.78 4.69 2.15 6.15 1.37 1.47 3.08 2.2 5.12 2.2 1.39 0 2.56-.38 3.51-1.14.95-.76 1.67-1.98 2.15-3.67Zm.51-8.98c-.06-2.57-.73-4.53-1.99-5.87-1.27-1.34-2.81-2.01-4.62-2.01-1.94 0-3.54.71-4.81 2.12-1.27 1.41-1.89 3.33-1.87 5.76h13.28Zm46.62 19.67h-8.89V75.23c0-3.63-.19-5.97-.57-7.04-.38-1.06-1-1.89-1.85-2.48s-1.88-.89-3.08-.89c-1.54 0-2.92.42-4.14 1.27s-2.06 1.96-2.51 3.35c-.45 1.39-.68 3.96-.68 7.72v15.21h-8.89V58.78h8.26v4.93c2.93-3.8 6.62-5.69 11.07-5.69 1.96 0 3.75.35 5.38 1.06 1.62.71 2.85 1.61 3.68 2.7.83 1.1 1.41 2.34 1.74 3.73s.49 3.38.49 5.98v20.88Zm24.42-33.59v7.08h-6.07V79.4c0 2.74.06 4.34.17 4.79.12.45.38.83.79 1.12.41.3.91.44 1.5.44.82 0 2.01-.28 3.57-.85l.76 6.9c-2.07.89-4.41 1.33-7.02 1.33-1.6 0-3.05-.27-4.33-.81-1.29-.54-2.23-1.23-2.83-2.09-.6-.85-1.02-2.01-1.25-3.46-.19-1.03-.28-3.12-.28-6.26V65.86h-4.08v-7.08h4.08v-6.67l8.92-5.19v11.86h6.07Zm6.26 33.59V46h6.14v40.9h22.84v5.47h-28.97Zm57.47-4.14c-2.11 1.79-4.14 3.06-6.09 3.8-1.95.74-4.04 1.11-6.28 1.11-3.69 0-6.53-.9-8.51-2.7-1.98-1.8-2.97-4.11-2.97-6.91 0-1.64.37-3.15 1.12-4.51s1.73-2.45 2.94-3.27c1.21-.82 2.58-1.44 4.1-1.87 1.12-.3 2.8-.58 5.06-.85 4.6-.55 7.98-1.2 10.15-1.96.02-.78.03-1.28.03-1.49 0-2.32-.54-3.95-1.61-4.9-1.46-1.29-3.62-1.93-6.48-1.93-2.68 0-4.65.47-5.93 1.41s-2.22 2.6-2.83 4.98l-5.57-.76c.51-2.38 1.34-4.31 2.5-5.77 1.16-1.47 2.84-2.59 5.03-3.38 2.19-.79 4.73-1.19 7.62-1.19s5.2.34 6.99 1.01c1.79.68 3.11 1.52 3.95 2.55.84 1.02 1.43 2.31 1.77 3.88.19.97.28 2.72.28 5.25v7.59c0 5.29.12 8.64.36 10.04.24 1.4.72 2.75 1.44 4.03h-5.95c-.59-1.18-.97-2.56-1.14-4.14Zm-.47-12.72c-2.07.84-5.17 1.56-9.3 2.15-2.34.34-4 .72-4.97 1.14-.97.42-1.72 1.04-2.25 1.85s-.79 1.71-.79 2.7c0 1.52.57 2.78 1.72 3.8 1.15 1.01 2.83 1.52 5.05 1.52s4.14-.48 5.85-1.44 2.96-2.27 3.76-3.94c.61-1.29.92-3.18.92-5.69v-2.09Zm14.33 29.8-.63-5.35c1.24.34 2.33.51 3.26.51 1.27 0 2.28-.21 3.04-.63s1.38-1.01 1.87-1.77c.36-.57.94-1.98 1.74-4.24.11-.32.27-.78.51-1.39l-12.75-33.65h6.14l6.99 19.45c.91 2.47 1.72 5.06 2.44 7.78.65-2.61 1.43-5.17 2.34-7.65l7.18-19.58h5.69l-12.78 34.16c-1.37 3.69-2.44 6.23-3.19 7.62-1.01 1.88-2.17 3.25-3.48 4.13-1.31.88-2.87 1.31-4.68 1.31-1.1 0-2.32-.23-3.67-.7Zm55.63-23.76 5.88.73c-.93 3.44-2.65 6.1-5.16 8-2.51 1.9-5.71 2.85-9.62 2.85-4.91 0-8.81-1.51-11.69-4.54-2.88-3.03-4.32-7.27-4.32-12.73s1.46-10.04 4.36-13.16c2.91-3.12 6.68-4.68 11.32-4.68s8.16 1.53 11.01 4.59c2.85 3.06 4.27 7.36 4.27 12.91 0 .34-.01.84-.03 1.52h-25.05c.21 3.69 1.25 6.52 3.13 8.48 1.88 1.96 4.22 2.94 7.02 2.94 2.09 0 3.87-.55 5.35-1.64 1.48-1.1 2.65-2.85 3.51-5.25Zm-18.69-9.2h18.76c-.25-2.83-.97-4.94-2.15-6.36-1.81-2.19-4.17-3.29-7.05-3.29-2.61 0-4.81.88-6.6 2.63s-2.77 4.09-2.96 7.02Zm31.66 20.02V58.78h5.12v5.09c1.31-2.38 2.51-3.95 3.62-4.71s2.32-1.14 3.65-1.14c1.92 0 3.87.61 5.85 1.83l-1.96 5.28c-1.39-.82-2.78-1.23-4.18-1.23-1.24 0-2.36.37-3.35 1.12-.99.75-1.7 1.79-2.12 3.12-.63 2.02-.95 4.24-.95 6.64v17.59h-5.69Zm21.79 0V46h9.36v46.37h-9.36ZM407.37 46h17.11c3.86 0 6.8.3 8.83.89 2.72.8 5.05 2.22 6.99 4.27 1.94 2.05 3.42 4.55 4.43 7.51 1.01 2.96 1.52 6.62 1.52 10.96 0 3.82-.47 7.11-1.42 9.87-1.16 3.37-2.82 6.1-4.97 8.19-1.62 1.58-3.82 2.82-6.58 3.7-2.07.65-4.83.98-8.29.98h-17.62V46Zm9.36 7.84v30.71h6.99c2.61 0 4.5-.15 5.66-.44 1.52-.38 2.78-1.02 3.78-1.93 1-.91 1.82-2.4 2.45-4.48.63-2.08.95-4.91.95-8.49s-.32-6.34-.95-8.26-1.52-3.42-2.66-4.49-2.58-1.8-4.33-2.18c-1.31-.3-3.87-.44-7.69-.44h-4.21Z" style="fill:#fff"/><text y="670" x="30" style="font:70px sans-serif;fill:#fff">',
                        username,
                        "</text></svg>"
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                username,
                                '", "image":"',
                                image,
                                unicode'", "description": "TalentLayer ID"}'
                            )
                        )
                    )
                )
            );
    }

    // =========================== Modifiers ==============================
    /**
     * Check if is possible to mint a TalentLayerID for a given address.
     * @param _userAddress Address to mint TalentLayer for.
     * @param _handle Handle for the user
     * @param _platformId Platform that wants to mint the TalentLayerID
     */
    modifier canPayAndMint(address _userAddress, string memory _handle, uint256 _platformId) {
        _canPay();
        _canMint(_userAddress, _handle, _platformId);
        _;
    }

    /**
     * Check if it is possible to mint a new TalentLayerID for a given address.
     * @param _userAddress Address to mint TalentLayer for.
     * @param _handle Handle for the user
     * @param _platformId Platform that wants to mint the TalentLayerID
     */
    modifier canMint(address _userAddress, string memory _handle, uint256 _platformId) {
        _canMint(_userAddress, _handle, _platformId);
        _;
    }
    // =========================== Events ==============================

    /**
     * Emit when new TalentLayerID is minted.
     * @param _user Address of the owner of the TalentLayerID
     * @param _tokenId TalentLayer ID for the user
     * @param _handle Handle for the user
     * @param _platformId Platform ID from which UserId wad minted
     * @param _fee Fee paid to mint the TalentLayerID
     */
    event Mint(
        address indexed _user,
        uint256 _tokenId,
        string _handle,
        bool _withPoh,
        uint256 _platformId,
        uint256 _fee
    );

    /**
     * Emit when new Proof of Identity is linked to TalentLayerID.
     * @param _user Address of the owner of the TalentLayerID
     * @param _tokenId TalentLayer ID for the user
     * @param _handle Handle for the user
     */
    event PohActivated(address indexed _user, uint256 _tokenId, string _handle);

    /**
     * Emit when Cid is updated for a user.
     * @param _tokenId TalentLayer ID for the user
     * @param _newCid Content ID
     */
    event CidUpdated(uint256 indexed _tokenId, string _newCid);

    /**
     * Emit when account is recovered.
     * @param _newAddress New user address
     * @param _oldAddress Old user address
     * @param _handle User handle
     * @param _tokenId TalentLayer ID for the user
     */
    event AccountRecovered(address indexed _newAddress, address indexed _oldAddress, string _handle, uint256 _tokenId);

    /**
     * Emit when mint fee is updated
     * @param _mintFee The new mint fee
     */
    event MintFeeUpdated(uint256 _mintFee);
}
