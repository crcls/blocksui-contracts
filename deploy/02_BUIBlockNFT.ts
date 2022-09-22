import { ethers } from 'hardhat'

import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const PRICE = ethers.utils.parseEther('0.1')

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const Contract = await hre.ethers.getContractFactory('BUIBlockNFT')

  const [deployer] = await hre.ethers.getSigners()
  console.log('Using account: ', deployer.address)
  const accountBalance = await deployer.getBalance()
  console.log('Account balance: ', accountBalance.toString())

  const contract = await Contract.deploy(PRICE)

  await contract.deployed()
  const { transactionHash, gasUsed } = await contract.deployTransaction.wait()

  console.log('Args', PRICE.toString())
  console.log('Transaction Hash:', transactionHash)
  console.log('Contract deployed to:', contract.address)
  console.log('Cost to deploy:', ethers.utils.formatEther(gasUsed))
}

func.tags = ['BUIBlockNFT']
func.skip = async () => {
  return !['all', 'BUIBlockNFT'].includes(process.env.CONTRACT)
}

export default func
