import { ethers } from 'hardhat'

import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const MARKETPLACE = '0x83BA18B514386A1280C7310c8e865c046d259801'
const BLOCKSNFT = '0xBd678E358B27a3A6a14a804AeD4C5ed6323C4dC1'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const Contract = await hre.ethers.getContractFactory('BUILicenseNFT')

  const [deployer] = await hre.ethers.getSigners()
  console.log('Using account: ', deployer.address)
  const accountBalance = await deployer.getBalance()
  console.log('Account balance: ', accountBalance.toString())

  const contract = await Contract.deploy(MARKETPLACE, BLOCKSNFT)

  await contract.deployed()
  const { transactionHash, gasUsed } = await contract.deployTransaction.wait()

  console.log('Args', MARKETPLACE, BLOCKSNFT)
  console.log('Transaction Hash:', transactionHash)
  console.log('Contract deployed to:', contract.address)
  console.log('Cost to deploy:', ethers.utils.formatEther(gasUsed))
}

func.tags = ['BUILicenseNFT']
func.skip = async () => {
  return !['all', 'BUILicenseNFT'].includes(process.env.CONTRACT)
}

export default func
