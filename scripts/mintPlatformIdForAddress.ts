import {task} from 'hardhat/config'
import {Network} from './config'
import {ConfigProperty, get} from "../configManager";

/**
 * @notice This task is used to mint a new platform ID for a given address
 * @param {string} name - The name of the platform
 * @param {string} address - The address of the platform
 * @dev Example of script use: "npx hardhat mint-platform-id --name HireVibes --address 0x5FbDB2315678afecb367f032d93F642f64180aa3 --network goerli"
 */
task("mint-platform-id", "Mints platform Ids to addresses")
  .addParam("name", "The platform's name")
  .addParam("address", "The platform's address")
  .setAction(async (taskArgs, { ethers, network }) => {
    const { name, address } = taskArgs;
    const [deployer] = await ethers.getSigners();

    console.log('network', network.name);

    const platformIdContract = await ethers.getContractAt(
      'TalentLayerPlatformID',
      get(network.name as any as Network, ConfigProperty.TalentLayerPlatformID),
      deployer)

    const mintRole = await platformIdContract.MINT_ROLE();
    await platformIdContract.grantRole(mintRole, deployer.address);

    // const tx = await platformIdContract.mintForAddress(name, address);
    // await tx.wait();
    const platformId = await platformIdContract.getPlatformIdFromAddress(address);
    console.log(`Minted platform id: ${platformId} for address ${address}`);
  });
