import * as dotenv from 'dotenv'
dotenv.config()

import { HardhatUserConfig, task, types } from 'hardhat/config'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import 'hardhat-deploy'
import 'hardhat-deploy-ethers'

import { Web3Storage, getFilesFromPath } from 'web3.storage'

task(
  'ipfs-deploy',
  'Deploy the contract ABI to web3.storage',
  async (taskArgs, hre) => {
    const client = new Web3Storage({ token: process.env.WEB3STORAGE_TOKEN })
    const files = await getFilesFromPath('./ipfs')
    const dirCID = await client.put(files)

    console.log('ABIs uploaded to:', dirCID)
  }
)

const {
  ETHERSCAN_API_KEY,
  MAINNET_ALCHEMY_API,
  GOERLI_ALCHEMY_API,
  MUMBAI_ALCHEMY_API,
  POLYGON_ALCHEMY_API,
} = process.env

const { MAINNET_ETHERSCAN, MUMBAI_POLYSCAN } = process.env

const envAccounts = [
  process.env.ACCOUNT_1!,
  process.env.ACCOUNT_2!,
  process.env.ACCOUNT_3!,
]

const config: HardhatUserConfig = {
  solidity: '0.8.17',
  networks: {
    hardhat: {
      accounts: {
        accountsBalance: '10000000000000000000000000',
      },
    },
    localhost: {
      live: false,
    },
    goerli: {
      forking: {
        url: `https://eth-goerli.g.alchemy.com/v2/${GOERLI_ALCHEMY_API}`,
      },
      url: `https://eth-goerli.g.alchemy.com/v2/${GOERLI_ALCHEMY_API}`,
      accounts: envAccounts,
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${MAINNET_ALCHEMY_API}`,
      accounts: envAccounts,
    },
    mumbai: {
      forking: {
        url: `https://polygon-mumbai.g.alchemy.com/v2/${MUMBAI_ALCHEMY_API}`,
      },
      url: `https://polygon-mumbai.g.alchemy.com/v2/${MUMBAI_ALCHEMY_API}`,
      accounts: envAccounts,
    },
    polygon: {
      forking: {
        url: `https://polygon-mainnet.g.alchemy.com/v2/${POLYGON_ALCHEMY_API}`,
      },
      url: `https://polygon-mainnet.g.alchemy.com/v2/${POLYGON_ALCHEMY_API}`,
      accounts: envAccounts,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: {
      mainnet: MAINNET_ETHERSCAN,
      polygonMumbai: MUMBAI_POLYSCAN,
    },
  },
}

export default config
export default config
