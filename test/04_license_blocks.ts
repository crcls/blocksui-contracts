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

describe('BUILicenseNFT', function () {
  let blockContract: Contract | undefined
  let marketContract: Contract | undefined
  let contract: Contract | undefined

  before(async () => {
    const BUIBlockNFT = await ethers.getContractFactory('BUIBlockNFT')
    blockContract = await BUIBlockNFT.deploy(ethers.utils.parseEther('0.5'))
    await blockContract.deployed()

    await blockContract.publish(cid, 'ipfs://test', {
      value: ethers.utils.parseEther('0.5'),
    })

    const BUIMarketplace = await ethers.getContractFactory('BUIMarketplace')
    marketContract = await BUIMarketplace.deploy(
      blockContract.address,
      ethers.utils.parseEther('0.01')
    )
    await marketContract.deployed()

    await marketContract.listBlock(
      'ipfs://test',
      ethers.utils.parseEther('0.0001'),
      0,
      1,
      true,
      { value: ethers.utils.parseEther('0.01') }
    )

    const BUILicenseNFT = await ethers.getContractFactory('BUILicenseNFT')
    contract = await BUILicenseNFT.deploy(
      marketContract.address,
      blockContract.address
    )
    await contract.deployed()
  })

  it('fails when block does not exist', async () => {
    await expect(
      contract.purchaseLicense(2, thirtyDays, origin)
    ).to.be.revertedWith('ERC721: invalid token ID')
  })

  it('fails if the sender if the Block owner', async () => {
    await expect(
      contract.purchaseLicense(1, thirtyDays, origin, {
        value: ethers.utils.parseEther('0.003'),
      })
    ).to.be.revertedWith('License not required for Block owner')
  })

  it('fails when there is no listing for a Block', async () => {
    const [, acc] = await ethers.getSigners()

    await blockContract.publish(
      getBytes32FromIpfsHash('QmTBV6zgUqwTPNWSRYL5W9dmcHzYxosvgKgno9obB3EuU4'),
      'ipfs://test',
      {
        value: ethers.utils.parseEther('0.5'),
      }
    )

    await expect(
      contract.connect(acc).purchaseLicense(2, thirtyDays, origin)
    ).to.be.revertedWith('No listing for this Block')
  })

  it('fails if the listing is not licensable', async () => {
    const [, acc] = await ethers.getSigners()

    await marketContract.listBlock(
      'ipfs://test',
      0,
      ethers.utils.parseEther('10'),
      2,
      false,
      { value: ethers.utils.parseEther('0.01') }
    )

    await expect(
      contract.connect(acc).purchaseLicense(2, thirtyDays, origin)
    ).to.be.revertedWith('Block cannot be licensed')
  })

  it('fails with insufficient funds', async () => {
    const [, acc] = await ethers.getSigners()

    await expect(contract.connect(acc).purchaseLicense(1, thirtyDays, origin))
      .to.be.reverted
  })

  it('succeeds to license a Block', async () => {
    const [owner, acc] = await ethers.getSigners()

    const tx = await contract
      .connect(acc)
      .purchaseLicense(1, thirtyDays, origin, {
        value: ethers.utils.parseEther('0.003'),
      })

    await tx.wait()

    expect(tx).to.emit('BUILicensePurchased').withArgs(1, thirtyDays, cid)
    await expect(tx).to.changeEtherBalance(
      owner,
      ethers.utils.parseEther('0.003')
    )
  })
})
