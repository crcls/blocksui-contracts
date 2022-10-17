import { Contract } from '@ethersproject/contracts'
import { expect } from 'chai'
import { ethers } from 'hardhat'

import { getBytes32FromIpfsHash } from '../helpers/bytes'

const ipfsHash = 'QmWmyoMoctfbAaiEs2G46gpeUmhqFRDW6KWo64y5r581Vz'
const cid = getBytes32FromIpfsHash(ipfsHash)
const thirtyDays = 60 * 60 * 24 * 30
const origin = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes('http://example.com')
)

describe('BUIOriginRegistry', function () {
  let contract: Contract | undefined

  before(async () => {
    const BUIOriginRegistry = await ethers.getContractFactory(
      'BUIOriginRegistry'
    )
    contract = await BUIOriginRegistry.deploy(ethers.utils.parseEther('0.1'))
    await contract.deployed()
  })

  it('fails when not enough stake', async () => {
    await expect(contract.register('http://example.com')).to.be.revertedWith(
      'Must meet the minimum balance requirement'
    )
  })

  it('succeeds to register an origin', async () => {
    const [acc] = await ethers.getSigners()
    await expect(
      contract.register('http://example.com', {
        value: ethers.utils.parseEther('0.1'),
      })
    )
      .to.emit(contract, 'OriginRegistered')
      .withArgs(acc.address, origin)
  })

  it('fails when the origin is already registered', async () => {
    await expect(
      contract.register('http://example.com', {
        value: ethers.utils.parseEther('0.1'),
      })
    ).to.be.revertedWith('This origin is already registered')
  })

  it('succeeds to verify owner', async () => {
    const [acc] = await ethers.getSigners()
    expect(await contract.verifyOwner(origin, acc.address)).to.be.true
  })

  it('fails to verify owner', async () => {
    const [, acc] = await ethers.getSigners()
    expect(await contract.verifyOwner(origin, acc.address)).to.be.false
  })

  it('returns a list of origins for sender', async () => {
    await contract.register('https://crcls.xyz', {
      value: ethers.utils.parseEther('0.1'),
    })

    const origins = await contract.originsForSender()
    expect(origins).to.deep.equal(['http://example.com', 'https://crcls.xyz'])
  })

  it('fails to unregister when not the owner', async () => {
    const [, acc] = await ethers.getSigners()
    await expect(contract.connect(acc).unregister(origin)).to.be.revertedWith(
      'Not authorized'
    )
  })

  it('succeeds to unregister', async () => {
    const [acc] = await ethers.getSigners()
    const tx = await contract.unregister(origin)
    await expect(tx)
      .to.emit(contract, 'OriginUnregistered')
      .withArgs(acc.address, origin)
  })

  it('prevents withdraw by non owner', async () => {
    const [, acc] = await ethers.getSigners()

    await expect(contract.connect(acc).withdraw()).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
  })

  it('is able to withdraw funds', async () => {
    const [acc] = await ethers.getSigners()
    const balance = await acc.provider.getBalance(contract.address)

    expect(await contract.withdraw()).to.changeEtherBalance(acc, balance)
  })
})
