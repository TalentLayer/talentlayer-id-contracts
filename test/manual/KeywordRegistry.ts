import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Contract, ContractFactory } from 'ethers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

describe('KeywordRegistry tests', function () {
	let signers: SignerWithAddress[],
	deployer: SignerWithAddress,
	alice: SignerWithAddress,
	bob: SignerWithAddress,
	carol: SignerWithAddress,
	KeywordRegistry: ContractFactory,
	keywordRegistry: Contract;

	before(async function () {
		signers = await ethers.getSigners();
		deployer = signers[0];
		alice = signers[1];
		bob = signers[2];
		carol = signers[3];

		// Deploy Contract
		KeywordRegistry = await ethers.getContractFactory('KeywordRegistry');
		keywordRegistry = await KeywordRegistry.deploy();
	});

	describe("Creating Keywords", async function () {
		const addKeywordSuccess = async function (keyword: string, keywordID: number){
			return expect(await keywordRegistry.addKeyword(keyword))
				.to.emit(keywordRegistry, 'KeywordCreated')
				.withArgs(keywordID, keyword);
		}

		const addKeywordReverted = async function (keyword: string){
			return 
		}

		it("Can add a keyword", async function () {
			await addKeywordSuccess("First", 0);
		});

		it("Can add another keyword", async function () {
			await addKeywordSuccess("Second", 1);
		});

		it("Can get the ID of a keyword", async function () {
			expect(await keywordRegistry.getKeywordID("First")).to.be.equal(0);
		});

		it("Trying to add a keyword that already exists returns its ID", async function () {
			await addKeywordSuccess("First", 0);
		});

		it("Only the owner can add keywords", async function () {
			let keyword = "Red";
			await expect(keywordRegistry.connect(alice).addKeyword(keyword))
				.to.be.revertedWith('Ownable: caller is not the owner');
		});

		it("Only the owner can update the keyword list", async function () {
			let keywords = ["Red", "Blue", "Green", "Orange"];
			await expect(keywordRegistry.connect(alice).updateKeywordList(keywords))
				.to.be.revertedWith('Ownable: caller is not the owner');
			
			await expect(keywordRegistry.connect(deployer).updateKeywordList(keywords))
				.to.not.be.reverted;
		});

		it("Can get the ID of a keyword from the new list", async function () {
			expect(await keywordRegistry.getKeywordID("Green")).to.be.equal(2);
		});
	});
});