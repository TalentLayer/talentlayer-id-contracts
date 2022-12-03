// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITalentLayerID} from "./interfaces/ITalentLayerID.sol";
import {ITalentLayerPlatformID} from "./interfaces/ITalentLayerPlatformID.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title ServiceRegistry Contract
 * @author TalentLayer Team @ ETHCC22 Hackathon
 */
contract ServiceRegistry is AccessControl {
    // =========================== Enum ==============================

    /// @notice Enum service status
    enum Status {
        Filled,
        Confirmed,
        Finished,
        Rejected,
        Opened
    }

    /// @notice Enum service status
    enum ProposalStatus {
        Pending,
        Validated,
        Rejected
    }

    // =========================== Struct ==============================

    /// @notice Service information struct
    /// @param status the current status of a service
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param initiatorId the talentLayerId of the user who initialized the service
    /// @param serviceDataUri token Id to IPFS URI mapping
    /// @param proposals all proposals for this service
    /// @param countProposals the total number of proposal for this service
    /// @param transactionId the escrow transaction ID linked to the service
    /// @param platformId the platform ID linked to the service
    struct Service {
        Status status;
        uint256 buyerId;
        uint256 sellerId;
        uint256 initiatorId;
        string serviceDataUri;
        uint256 countProposals;
        uint256 transactionId;
        uint256 platformId;
    }

    /// @notice Proposal information struct
    /// @param status the current status of a service
    /// @param sellerId the talentLayerId of the seller
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    /// @param proposalDataUri token Id to IPFS URI mapping
    struct Proposal {
        ProposalStatus status;
        uint256 sellerId;
        address rateToken;
        uint256 rateAmount;
        string proposalDataUri;
    }

    // =========================== Events ==============================

    /// @notice Emitted after a new service is created
    /// @param id The service ID (incremental)
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param initiatorId the talentLayerId of the user who initialized the service
    /// @param platformId platform ID on which the Service token was minted
    /// @dev Events "ServiceCreated" & "ServiceDataCreated" are split to avoid "stack too deep" error
    event ServiceCreated(uint256 id, uint256 buyerId, uint256 sellerId, uint256 initiatorId, uint256 platformId);

    /// @notice Emitted after a new service is created
    /// @param id The service ID (incremental)
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceDataCreated(uint256 id, string serviceDataUri, uint32[8] keywordIDs);

    /// @notice Emitted after an seller is assigned to a service
    /// @param id The service ID
    /// @param sellerId the talentLayerId of the seller
    /// @param status service status
    event ServiceSellerAssigned(uint256 id, uint256 sellerId, Status status);

    /// @notice Emitted after a service is confirmed
    /// @param id The service ID
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceConfirmed(uint256 id, uint256 buyerId, uint256 sellerId, string serviceDataUri);

    /// @notice Emitted after a service is rejected
    /// @param id The service ID
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceRejected(uint256 id, uint256 buyerId, uint256 sellerId, string serviceDataUri);

    /// @notice Emitted after a service is finished
    /// @param id The service ID
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceFinished(uint256 id, uint256 buyerId, uint256 sellerId, string serviceDataUri);

    /**
     * Emit when Cid is updated for a Service
     * @param id The service ID
     * @param newServiceDataUri New service Data URI
     */
    event ServiceDetailedUpdated(uint256 indexed id, string newServiceDataUri);

    /// @notice Emitted after a new proposal is created
    /// @param serviceId The service id
    /// @param sellerId The talentLayerId of the seller who made the proposal
    /// @param proposalDataUri token Id to IPFS URI mapping
    /// @param status proposal status
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    event ProposalCreated(
        uint256 serviceId,
        uint256 sellerId,
        string proposalDataUri,
        ProposalStatus status,
        address rateToken,
        uint256 rateAmount
    );

    /// @notice Emitted after an existing proposal has been updated
    /// @param serviceId The service id
    /// @param sellerId The talentLayerId of the seller who made the proposal
    /// @param proposalDataUri token Id to IPFS URI mapping
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    event ProposalUpdated(
        uint256 serviceId,
        uint256 sellerId,
        string proposalDataUri,
        address rateToken,
        uint256 rateAmount
    );

    /// @notice Emitted after a proposal is validated
    /// @param serviceId The service ID
    /// @param sellerId the talentLayerId of the seller
    event ProposalValidated(uint256 serviceId, uint256 sellerId);

    /// @notice Emitted after a proposal is rejected
    /// @param serviceId The service ID
    /// @param sellerId the talentLayerId of the seller
    event ProposalRejected(uint256 serviceId, uint256 sellerId);

    /// @notice incremental service Id
    uint256 public nextServiceId = 1;

    /// @notice TalentLayerId address
    ITalentLayerID private tlId;

    /// TalentLayer Platform ID registry
    ITalentLayerPlatformID public talentLayerPlatformIdContract;

    /// @notice services mappings index by ID
    mapping(uint256 => Service) public services;

    /// @notice proposals mappings index by service ID and seller TID
    mapping(uint256 => mapping(uint256 => Proposal)) public proposals;

    // @notice
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");

    /**
     * @param _talentLayerIdAddress TalentLayerId address
     */
    constructor(address _talentLayerIdAddress, address _talentLayerPlatformIdAddress) {
        tlId = ITalentLayerID(_talentLayerIdAddress);
        talentLayerPlatformIdContract = ITalentLayerPlatformID(_talentLayerPlatformIdAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================

    /**
     * @notice Return the whole service data information
     * @param _serviceId Service identifier
     */
    function getService(uint256 _serviceId) external view returns (Service memory) {
        require(_serviceId < nextServiceId, "This service doesn't exist");
        return services[_serviceId];
    }

    function getProposal(uint256 _serviceId, uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_serviceId][_proposalId];
    }

    // =========================== User functions ==============================

    /**
     * @notice Allows an buyer to initiate a new Service with an seller
     * @param _platformId platform ID on which the Service token was minted
     * @param _sellerId Handle for the user
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function createServiceFromBuyer(
        uint256 _platformId,
        uint256 _sellerId,
        string calldata _serviceDataUri,
        uint32[] memory keywordIDs
    ) public returns (uint256) {
        talentLayerPlatformIdContract.isValid(_platformId);
        tlId.isValid(_sellerId);
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createService(Status.Filled, senderId, senderId, _sellerId, _serviceDataUri, _platformId, packKeywordIDs(keywordIDs));
    }

    /**
     * @notice Allows an seller to initiate a new Service with an buyer
     * @param _platformId platform ID on which the Service token was minted
     * @param _buyerId Handle for the user
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function createServiceFromSeller(
        uint256 _platformId,
        uint256 _buyerId,
        string calldata _serviceDataUri,
        uint32[] memory keywordIDs
    ) public returns (uint256) {
        talentLayerPlatformIdContract.isValid(_platformId);
        tlId.isValid(_buyerId);
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createService(Status.Filled, senderId, _buyerId, senderId, _serviceDataUri, _platformId, packKeywordIDs(keywordIDs));
    }

//===================== KEYWORD ID PROOF OF CONCEPT FUNCTION FOR PACKING KEYWORD IDS ====================
    function packKeywordIDs(uint32[] memory keywordIDs) private pure returns (uint32[8] memory packedKeywordIDs){
        uint32[8] memory fixedLengthKeywordIDs;
        
        for(uint8 i = 0; i < 8 && i < keywordIDs.length; i++){
            fixedLengthKeywordIDs[i] = keywordIDs[i];
        }
        
        return fixedLengthKeywordIDs;
    }

    /**
     * @notice Allows an buyer to initiate an open service
     * @param _platformId platform ID on which the Service token was minted
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function createOpenServiceFromBuyer(uint256 _platformId, string calldata _serviceDataUri, uint32[] memory keywordIDs) public returns (uint256) {
        talentLayerPlatformIdContract.isValid(_platformId);
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createService(Status.Opened, senderId, senderId, 0, _serviceDataUri, _platformId, packKeywordIDs(keywordIDs));
    }

    /**
     * @notice Allows an seller to propose his service for a service
     * @param _serviceId The service linked to the new proposal
     * @param _rateToken the token choose for the payment
     * @param _rateAmount the amount of token choosed
     * @param _proposalDataUri token Id to IPFS URI mapping
     */
    function createProposal(
        uint256 _serviceId,
        address _rateToken,
        uint256 _rateAmount,
        string calldata _proposalDataUri
    ) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        require(service.status == Status.Opened, "Service is not opened");
        require(
            proposals[_serviceId][senderId].sellerId != senderId,
            "You already created a proposal for this service"
        );
        require(service.countProposals < 40, "Max proposals count reached");
        require(service.buyerId != senderId, "You couldn't create proposal for your own service");
        require(bytes(_proposalDataUri).length > 0, "Should provide a valid IPFS URI");

        service.countProposals++;
        proposals[_serviceId][senderId] = Proposal({
            status: ProposalStatus.Pending,
            sellerId: senderId,
            rateToken: _rateToken,
            rateAmount: _rateAmount,
            proposalDataUri: _proposalDataUri
        });

        emit ProposalCreated(_serviceId, senderId, _proposalDataUri, ProposalStatus.Pending, _rateToken, _rateAmount);
    }

    /**
     * @notice Allows an seller to update his own proposal for a given service
     * @param _serviceId The service linked to the new proposal
     * @param _rateToken the token choose for the payment
     * @param _rateAmount the amount of token choosed
     * @param _proposalDataUri token Id to IPFS URI mapping
     */
    function updateProposal(
        uint256 _serviceId,
        address _rateToken,
        uint256 _rateAmount,
        string calldata _proposalDataUri
    ) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][senderId];
        require(service.status == Status.Opened, "Service is not opened");
        require(proposal.sellerId == senderId, "This proposal doesn't exist yet");
        require(bytes(_proposalDataUri).length > 0, "Should provide a valid IPFS URI");
        require(proposal.status != ProposalStatus.Validated, "This proposal is already updated");

        proposal.rateToken = _rateToken;
        proposal.rateAmount = _rateAmount;
        proposal.proposalDataUri = _proposalDataUri;

        emit ProposalUpdated(_serviceId, senderId, _proposalDataUri, _rateToken, _rateAmount);
    }

    /**
     * @notice Allows the buyer to validate a proposal
     * @param _serviceId Service identifier
     * @param _proposalId Proposal identifier
     */
    function validateProposal(uint256 _serviceId, uint256 _proposalId) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][_proposalId];

        require(proposal.status != ProposalStatus.Validated, "Proposal has already been validated");
        require(senderId == service.buyerId, "You're not the buyer");

        proposal.status = ProposalStatus.Validated;

        emit ProposalValidated(_serviceId, _proposalId);
    }

    /**
     * @notice Allows the buyer to reject a proposal
     * @param _serviceId Service identifier
     * @param _proposalId Proposal identifier
     */
    function rejectProposal(uint256 _serviceId, uint256 _proposalId) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][_proposalId];

        require(proposal.status != ProposalStatus.Validated, "Proposal has already been validated");

        require(proposal.status != ProposalStatus.Rejected, "Proposal has already been rejected");

        require(senderId == service.buyerId, "You're not the buyer");

        proposal.status = ProposalStatus.Rejected;

        emit ProposalRejected(_serviceId, _proposalId);
    }

    /**
     * @notice Allows the user who didn't initiate the service to confirm it. They now consent both to be reviewed each other at the end of service.
     * @param _serviceId Service identifier
     */
    function confirmService(uint256 _serviceId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);

        require(service.status == Status.Filled, "Service has already been confirmed");
        require(senderId == service.buyerId || senderId == service.sellerId, "You're not an actor of this service");
        require(senderId != service.initiatorId, "Only the user who didn't initate the service can confirm it");

        service.status = Status.Confirmed;

        emit ServiceConfirmed(_serviceId, service.buyerId, service.sellerId, service.serviceDataUri);
    }

    /**
     * @notice Allow the escrow contract to upgrade the Service state after a deposit has been done
     * @param _serviceId Service identifier
     * @param _proposalId The choosed proposal id for this service
     * @param _transactionId The escrow transaction Id
     */
    function afterDeposit(
        uint256 _serviceId,
        uint256 _proposalId,
        uint256 _transactionId
    ) external onlyRole(ESCROW_ROLE) {
        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][_proposalId];

        service.status = Status.Confirmed;
        service.sellerId = proposal.sellerId;
        service.transactionId = _transactionId;
        proposal.status = ProposalStatus.Validated;
    }

    /**
     * @notice Allow the escrow contract to upgrade the Service state after the full payment has been received by the seller
     * @param _serviceId Service identifier
     */
    function afterFullPayment(uint256 _serviceId) external onlyRole(ESCROW_ROLE) {
        Service storage service = services[_serviceId];
        service.status = Status.Finished;
    }

    /**
     * @notice Allows the user who didn't initiate the service to reject it
     * @param _serviceId Service identifier
     */
    function rejectService(uint256 _serviceId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId == service.buyerId || senderId == service.sellerId, "You're not an actor of this service");
        require(service.status == Status.Filled || service.status == Status.Opened, "You can't reject this service");
        service.status = Status.Rejected;

        emit ServiceRejected(_serviceId, service.buyerId, service.sellerId, service.serviceDataUri);
    }

    /**
     * @notice Allows any part of a service to update his state to finished
     * @param _serviceId Service identifier
     */
    function finishService(uint256 _serviceId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId == service.buyerId || senderId == service.sellerId, "You're not an actor of this service");
        require(service.status == Status.Confirmed, "You can't finish this service");
        service.status = Status.Finished;

        emit ServiceFinished(_serviceId, service.buyerId, service.sellerId, service.serviceDataUri);
    }

    /**
     * @notice Allows the buyer to assign an seller to the service
     * @param _serviceId Service identifier
     * @param _sellerId Handle for the user
     */
    function assignSellerToService(uint256 _serviceId, uint256 _sellerId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        tlId.isValid(_sellerId);

        require(
            service.status == Status.Opened || service.status == Status.Rejected,
            "Service has to be Opened or Rejected"
        );

        require(senderId == service.buyerId, "You're not an buyer of this service");

        require(_sellerId != service.buyerId, "Seller and buyer can't be the same");

        service.sellerId = _sellerId;
        service.status = Status.Filled;

        emit ServiceSellerAssigned(_serviceId, _sellerId, service.status);
    }

    /**
     * Update Service URI data
     * @param _serviceId, Service ID to update
     * @param _newServiceDataUri New IPFS URI
     */
    function updateServiceData(uint256 _serviceId, string calldata _newServiceDataUri) public {
        Service storage service = services[_serviceId];
        require(_serviceId < nextServiceId, "This service doesn't exist");
        require(
            service.status == Status.Opened || service.status == Status.Filled,
            "Service status should be opened or filled"
        );
        require(service.initiatorId == tlId.walletOfOwner(msg.sender), "Only the initiator can update the service");
        require(bytes(_newServiceDataUri).length > 0, "Should provide a valid IPFS URI");

        service.serviceDataUri = _newServiceDataUri;

        emit ServiceDetailedUpdated(_serviceId, _newServiceDataUri);
    }

    // =========================== Private functions ==============================

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _senderId the talentLayerId of the msg.sender address
     * @param _buyerId the talentLayerId of the buyer
     * @param _sellerId the talentLayerId of the seller
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function _createService(
        Status _status,
        uint256 _senderId,
        uint256 _buyerId,
        uint256 _sellerId,
        string calldata _serviceDataUri,
        uint256 _platformId,
        uint32[8] memory keywordIDs
    ) private returns (uint256) {
        require(_senderId > 0, "You should have a TalentLayerId");
        require(_sellerId != _buyerId, "Seller and buyer can't be the same");
        require(bytes(_serviceDataUri).length > 0, "Should provide a valid IPFS URI");

        uint256 id = nextServiceId;
        nextServiceId++;

        Service storage service = services[id];
        service.status = _status;
        service.buyerId = _buyerId;
        service.sellerId = _sellerId;
        service.initiatorId = _senderId;
        service.serviceDataUri = _serviceDataUri;
        service.platformId = _platformId;

        emit ServiceCreated(id, _buyerId, _sellerId, _senderId, _platformId);

        emit ServiceDataCreated(id, _serviceDataUri, keywordIDs);

        return id;
    }
}
