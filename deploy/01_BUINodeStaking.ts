import { ethers } from 'hardhat'

import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const STAKE = ethers.utils.parseEther('0.1')

const conditions = [
  {
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
    chain,
    returnValueTest: {
      key: '',
      comparator: '=',
      value: 'true',
    },
  },
]

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const Contract = await hre.ethers.getContractFactory('BUINodeStaking')

  const [deployer] = await hre.ethers.getSigners()
  console.log('Using account: ', deployer.address)
  const accountBalance = await deployer.getBalance()
  console.log('Account balance: ', accountBalance.toString())

  const contract = await Contract.deploy(STAKE)

  await contract.deployed()
  const { transactionHash, gasUsed } = await contract.deployTransaction.wait()

  console.log('Args', STAKE.toString())
  console.log('Transaction Hash:', transactionHash)
  console.log('BUINodeStaking deployed to:', contract.address)
  console.log('Cost to deploy:', ethers.utils.formatEther(gasUsed))
}

func.tags = ['BUINodeStaking']
func.skip = async () => {
  return !['all', 'BUINodeStaking'].includes(process.env.CONTRACT)
}

export default func
