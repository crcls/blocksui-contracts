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

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    hardhat: {
      accounts: {
        accountsBalance: '10000000000000000000000000',
      },
    },
    localhost: {
      live: false,
    },
    rinkeby: {
      url: process.env.RINKEBY_URL || '',
      accounts: envAccounts,
    },
    mainnet: {
      url: process.env.MAINNET_URL,
      accounts: envAccounts,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
