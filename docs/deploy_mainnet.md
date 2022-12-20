
# Workflow


## To be prepared before deploy 

- Setup your local .env file to be able to execute all commands
    - Mandatory: 
        - ETHERSCAN_API_KEY: used to validate the contracts
        - MNEMONIC
        - INFURA_API_KEY: used by hardhat to deploy
    - Optional
        - GNOSIS_API_KEY: same than ETHERSCAN_API_KEY but only for Gnosis deployment
        - SUBGRAPH_FOLDER: useful to easly copy config into subgraph repo
        - DEPLOY_NETWORK: use by Makefile to define network for all commands
        - INFURA_ID & INFURA_SECRET: use by playground script to post json on IPFS
- Be sure that your address has enough fund, the gas usage to deploy the main contracts is: 17582534
- Note: if you have any issue in the command bellow, check the troubleshooting.md
- Replace the network used in the command bellow by the one you want to deploy to. For this documentation we use avalanche mainnet.

## Step 1: Contract deployment

- Deploy TL contracts: `npx hardhat deploy --network avalanche --verify`

## Step 2: Setup data

- Create our partners platformIds
    - `npx hardhat mint-platform-id --name HireVibes --address 0x5FbDB2315678afecb367f032d93F642f64180aa3 --network avalanche`
    - `npx hardhat mint-platform-id --name WorkPod --address 0x4444F618BA8E99435E721abF3c611D5105A407e9 --network avalanche`

## Step 3: Update Subgraph

### Update configuration 

- Update the abis from the contract folder to the graph folder
- Update network.json file with the new deployed addresses: `npx hardhat run scripts/setSubgraphNetwork.ts --network avalanche`
- Update the start block in the network.json. Use the block number of the first contract deployed

### Deploy your subgraph
  
- Generate code from your GraphQL schema and operations.: `graph codegen` 
- Copy configuration from network.json and buid graph code: `graph build --network avalanche` 
- Authenticad to the hosted service: `graph auth --network avalanche --product hosted-service <your access token>` 
- Deploy to the hosted service: `graph deploy --product hosted-service talentlayer/talent-layer-protocol`
  
 
## Step 4: Update Indie Frontend

- Update the abis in the frontend repo
- Fill the network const with the right deployed addresses in the **src > config.ts** file
