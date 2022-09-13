import { Contract } from '@ethersproject/contracts'
import { expect } from 'chai'
import { ethers } from 'hardhat'

const nodeAccount = ethers.Wallet.createRandom()
const nodeSigner = nodeAccount.connect(ethers.provider)

async function fundNode(ether: string) {
  const [deployer] = await ethers.getSigners()
  const tx = await deployer.sendTransaction({
    to: nodeAccount.address,
    value: ethers.utils.parseEther(ether),
  })

  await tx.wait()
}

describe('BUINodeStaking', function () {
  let contract: Contract | undefined

  before(async () => {
    const BUINodeStaking = await ethers.getContractFactory('BUINodeStaking')
    contract = await BUINodeStaking.deploy(ethers.utils.parseEther('1'))
    await contract.deployed()
  })

  it('returns false for a node that is not staking', async () => {
    expect(await contract.verify(nodeAccount.address)).to.be.false
  })

  it('fails to register with insufficient funds', async () => {
    await fundNode('0.6')

    await expect(
      contract.connect(nodeSigner).register({
        value: ethers.utils.parseEther('0.5'),
      })
    ).to.be.revertedWith('Not enough stake')
  })

  it('succeeds to register with sufficient stake', async () => {
    await fundNode('1.5')

    const tx = contract.connect(nodeSigner).register({
      value: ethers.utils.parseEther('1'),
    })

    await expect(tx).to.not.be.reverted
    expect(tx).to.changeEtherBalance(nodeAccount, '-1')
  })

  it('fails to stake twice', async () => {
    await fundNode('1.5')

    await expect(
      contract.connect(nodeSigner).register({
        value: ethers.utils.parseEther('1'),
      })
    ).to.be.revertedWith('Already registered')
  })

  it('succeeds to verify a staked node', async () => {
    expect(await contract.verify(nodeAccount.address)).to.be.true
  })

  it('succeeds to unregister a staked node', async () => {
    const tx = contract.connect(nodeSigner).unregister()
    await expect(tx).to.not.be.reverted
    expect(tx).to.changeEtherBalance(nodeAccount, '1')
  })

  it('fails to unregister a node not staked', async () => {
    const tx = contract.connect(nodeSigner).unregister()
    await expect(tx).to.be.revertedWith('No stake found')
  })

  it('allows the deployer to change the staking cost', async () => {
    await expect(
      contract
        .connect(nodeSigner)
        .setStakingCost(ethers.utils.parseEther('0.01'))
    ).to.be.revertedWith('Ownable: caller is not the owner')
  })

  it('allows the deployer to change the staking cost', async () => {
    await contract.setStakingCost(ethers.utils.parseEther('0.1'))

    await expect(
      contract.connect(nodeSigner).register({
        value: ethers.utils.parseEther('0.1'),
      })
    ).to.not.be.reverted
  })
})
