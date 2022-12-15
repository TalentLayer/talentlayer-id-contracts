import { task } from 'hardhat/config'
import { Network } from './config'
import { ConfigProperty, get } from '../configManager'

/**
 * @notice This task is used to mint a new TalentLayer ID for a given address
 * @param {string} name - The name of the platform
 * @param {string} address - The address of the platform
 * @dev Example of script use: "npx hardhat mint-platform-id --name HireVibes --address 0x5FbDB2315678afecb367f032d93F642f64180aa3 --network goerli"
 */
task('mint-talentlayer-id-free', 'Mints talentLayer Id to an addresses.')
  .addParam('platformId', "The platform's id")
  .addParam('userAddress', "The user's address")
  .addParam('userHandle', "The user's handle")
  .setAction(async (taskArgs, { ethers, network }) => {
    const { platformId, userAddress, userHandle } = taskArgs
    const [deployer] = await ethers.getSigners()

    console.log('network', network.name)

    const talentLayerIdContract = await ethers.getContractAt(
      'TalentLayerID',
      get((network.name as any) as Network, ConfigProperty.TalentLayerID),
      deployer,
    )

    const tx = await talentLayerIdContract.freeMint(platformId, userAddress, userHandle)
    await tx.wait()
    const talentLayerId = await talentLayerIdContract.walletOfOwner(userAddress)
    console.log(`Minted talentLayer id: ${talentLayerId} for address ${userAddress}`)
  })


task('mint-talentlayer-id-with-poh-free', 'Mints talentLayer Id to an addresses with poh for free.')
  .addParam('platformId', "The platform's id")
  .addParam('userAddress', "The user's address")
  .addParam('userHandle', "The user's handle")
  .setAction(async (taskArgs, { ethers, network }) => {
    const { platformId, userAddress, userHandle } = taskArgs
    const [deployer] = await ethers.getSigners()

    console.log('network', network.name)

    const talentLayerIdContract = await ethers.getContractAt(
      'TalentLayerID',
      get((network.name as any) as Network, ConfigProperty.TalentLayerID),
      deployer,
    )

    const tx = await talentLayerIdContract.freeMintWithPoh(platformId, userAddress, userHandle)
    await tx.wait()
    const talentLayerId = await talentLayerIdContract.walletOfOwner(userAddress)
    console.log(`Minted talentLayer id: ${talentLayerId} for address ${userAddress}`)
  })
