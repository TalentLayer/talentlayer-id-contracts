import type { HardhatUserConfig } from 'hardhat/config'
import type { NetworkUserConfig } from 'hardhat/types'
import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'
import '@nomicfoundation/hardhat-toolbox'
import 'hardhat-contract-sizer'
import './scripts/deploy'
import './scripts/wallet'
import './scripts/mintPlatformIdForAddress'
import './scripts/mintFreeTalentLayerID'
import { Network } from './scripts/config'

dotenvConfig({ path: resolve(__dirname, './.env') })

const mnemonic: string | undefined = process.env.MNEMONIC
if (!mnemonic) {
  throw new Error('Please set your MNEMONIC in a .env file')
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY
if (!infuraApiKey) {
  throw new Error('Please set your INFURA_API_KEY in a .env file')
}

function getChainConfig(chain: Network): NetworkUserConfig {
  let jsonRpcUrl: string
  switch (chain) {
    case Network.MAINNET:
      jsonRpcUrl = 'https://mainnet.infura.io/v3/' + infuraApiKey
      break
    case Network.GNOSIS:
      jsonRpcUrl = 'https://rpc.ankr.com/gnosis'
      break
    case Network.GOERLI:
      jsonRpcUrl = 'https://goerli.infura.io/v3/' + infuraApiKey
      break
    case Network.KOVAN:
      jsonRpcUrl = 'https://kovan.infura.io/v3/' + infuraApiKey
      break
    case Network.AVALANCHE:
      jsonRpcUrl = 'https://avalanche-mainnet.infura.io/v3/' + infuraApiKey
      break
    case Network.FUJI:
      jsonRpcUrl = 'https://avalanche-fuji.infura.io/v3/' + infuraApiKey
      break
    default:
      jsonRpcUrl = 'https://mainnet.infura.io/v3/' + infuraApiKey
  }

  return {
    accounts: {
      count: 10,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chain,
    url: jsonRpcUrl,
  }
}

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || '',
      xdai: process.env.GNOSIS_API_KEY || '',
      goerli: process.env.ETHERSCAN_API_KEY || '',
      kovan: process.env.ETHERSCAN_API_KEY || '',
      avalanche: process.env.SNOWTRACE_API_KEY || '',
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY || '',
    },
  },
  gasReporter: {
    currency: 'USD',
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    enabled: process.env.REPORT_GAS ? true : false,
    showTimeSpent: true,
    excludeContracts: [],
    src: './contracts',
    // noColors: true,
    // outputFile: "./reports/LoadTest",
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    only: ['TalentLayer', 'ServiceRegistry'],
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
        count: 100,
      },
      chainId: Network.LOCAL,
    },
    mainnet: getChainConfig(Network.MAINNET),
    goerli: getChainConfig(Network.GOERLI),
    gnosis: getChainConfig(Network.GNOSIS),
    kovan: getChainConfig(Network.KOVAN),
    avalanche: getChainConfig(Network.AVALANCHE),
    fuji: getChainConfig(Network.FUJI),
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test/batch',
  },
  solidity: {
    compilers: [
      {
        version: '0.8.9',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.5.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 1000000,
  },
}

export default config
