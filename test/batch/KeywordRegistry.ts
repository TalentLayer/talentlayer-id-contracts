import { expect } from 'chai'
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import { Contract, ContractFactory } from 'ethers'

describe('TalentLayer', function () {
  let deployer: SignerWithAddress,
    alice: SignerWithAddress,
    bob: SignerWithAddress,
    ServiceRegistry: ContractFactory,
    TalentLayerID: ContractFactory,
    TalentLayerPlatformID: ContractFactory,
    MockProofOfHumanity: ContractFactory,
    KeywordRegistry: ContractFactory,
    serviceRegistry: Contract,
    talentLayerID: Contract,
    talentLayerPlatformID: Contract,
    mockProofOfHumanity: Contract,
    keywordRegistry: Contract,
    platformName: string,
    platformId: string;

  before(async function () {
    [deployer, alice, bob] = await ethers.getSigners()

    // Deploy MockProofOfHumanity
    MockProofOfHumanity = await ethers.getContractFactory('MockProofOfHumanity')
    mockProofOfHumanity = await MockProofOfHumanity.deploy()
    mockProofOfHumanity.addSubmissionManually([alice.address, bob.address])

    // Deploy PlatformId
    TalentLayerPlatformID = await ethers.getContractFactory('TalentLayerPlatformID')
    talentLayerPlatformID = await TalentLayerPlatformID.deploy()

    // Deploy TalenLayerID
    TalentLayerID = await ethers.getContractFactory('TalentLayerID')
    const talentLayerIDArgs: [string, string] = [mockProofOfHumanity.address, talentLayerPlatformID.address]
    talentLayerID = await TalentLayerID.deploy(...talentLayerIDArgs)

    // Deploy ServiceRegistry
    ServiceRegistry = await ethers.getContractFactory('ServiceRegistry')
    const serviceRegistryArgs: [string, string] = [talentLayerID.address, talentLayerPlatformID.address]
    serviceRegistry = await ServiceRegistry.deploy(...serviceRegistryArgs)

    // Grant Platform Id Mint role to Alice
    const mintRole = await talentLayerPlatformID.MINT_ROLE()
    await talentLayerPlatformID.connect(deployer).grantRole(mintRole, alice.address)

    // Alice mints a Platform Id
    platformName = 'HireVibes'
    await talentLayerPlatformID.connect(alice).mint(platformName)

    KeywordRegistry = await ethers.getContractFactory('KeywordRegistry')
    keywordRegistry = await KeywordRegistry.deploy()
  })
  
  describe('Keyword registry unit tests', async function () {
    it("Adding new keywords emits event", async function () {
      await expect(await keywordRegistry.addKeywords(["solidity", "typescript", "rust"]))
      .to.emit(keywordRegistry, "KeywordsAdded")
      .withArgs(["solidity", "typescript", "rust"])
    });
  });

  describe("ServiceRegistry setup", async function () {
    it('Alice successfully minted a PlatformId Id', async function () {
      platformId = await talentLayerPlatformID.getPlatformIdFromAddress(alice.address)
      expect(platformId).to.be.equal('1')
    })

    it('Alice can mint a talentLayerId', async function () {
      await talentLayerID.connect(alice).mintWithPoh('1', 'alice')
      expect(await talentLayerID.walletOfOwner(alice.address)).to.be.equal('1')
    })

    it('Alice the buyer can create an Open service', async function () {
      let a = [1,2,3]
      let b = [1,2,3,0,0,0,0,0]
      await expect(await serviceRegistry.connect(alice).createOpenServiceFromBuyer(1, 'cid', a))
      .to.emit(serviceRegistry, "ServiceDataCreated")
      .withArgs(1, 'cid', b)
    })
  })
})
