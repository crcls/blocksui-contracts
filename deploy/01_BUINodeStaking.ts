import * as dotenv from 'dotenv'
dotenv.config()
import { webcrypto } from 'crypto'

import { ethers } from 'hardhat'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import LitJsSdk from '@lit-protocol/sdk-nodejs'

import { createAuthSig } from '../helpers/auth'

const client = new LitJsSdk.LitNodeClient()
const STAKE = ethers.utils.parseEther('0.1')

const condition = {
  contractAddress: '',
  functionName: 'verify',
  functionParams: [':userAddress'],
  functionAbi: {
    inputs: [
      {
        name: 'node',
        type: 'address',
      },
    ],
    name: 'verify',
    outputs: [
      {
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  returnValueTest: {
    key: '',
    comparator: '=',
    value: 'true',
  },
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const Contract = await hre.ethers.getContractFactory('BUINodeStaking')

  const [deployer] = await hre.ethers.getSigners()
  console.log('Using account: ', deployer.address)
  const accountBalance = await deployer.getBalance()
  console.log('Account balance: ', accountBalance.toString())

  const authSig = await createAuthSig(process.env.ACCOUNT_1, hre, 80001)
  console.log(authSig)

  const contract = await Contract.deploy(STAKE)
  await contract.deployed()
  const { transactionHash, gasUsed } = await contract.deployTransaction.wait()

  console.log('Args', STAKE.toString())
  console.log('Transaction Hash:', transactionHash)
  console.log('BUINodeStaking deployed to:', contract.address)
  console.log('Cost to deploy:', ethers.utils.formatEther(gasUsed))

  const chain = 'mumbai'
  const evmContractConditions = [
    {
      ...condition,
      contractAddress: '0x465fe903849d4d42ae674017BB5C7e20C9eB71a8',
      // contractAddress: contract.address,
      chain,
    },
  ]

  await client.connect()
  const key = await LitJsSdk.generateSymmetricKey()
  const symmetricKey = new Uint8Array(
    await webcrypto.subtle.exportKey('raw', key)
  )
  const encryptedSymmetricKey = await client.saveEncryptionKey({
    authSig,
    chain,
    evmContractConditions,
    symmetricKey,
  })

  console.log(
    'Encrypted Symmetric Key:',
    LitJsSdk.uint8arrayToString(encryptedSymmetricKey, 'hex')
  )
}

func.tags = ['BUINodeStaking']
func.skip = async () => {
  return !['all', 'BUINodeStaking'].includes(process.env.CONTRACT)
}

export default func
