import { Contract } from '@ethersproject/contracts'
import { expect } from 'chai'
import { ethers } from 'hardhat'

import { getBytes32FromIpfsHash } from '../helpers/bytes'

const ipfsHash = 'QmWmyoMoctfbAaiEs2G46gpeUmhqFRDW6KWo64y5r581Vz'
const cid = getBytes32FromIpfsHash(ipfsHash)

describe('BUIMarketplace', function () {
  let blockContract: Contract | undefined
  let contract: Contract | undefined

  before(async () => {
    const BUIBlockNFT = await ethers.getContractFactory('BUIBlockNFT')
    blockContract = await BUIBlockNFT.deploy(ethers.utils.parseEther('0.5'))
    await blockContract.deployed()

    await blockContract.publish(cid, 'ipfs://test', {
      value: ethers.utils.parseEther('0.5'),
    })

    const BUIMarketplace = await ethers.getContractFactory('BUIMarketplace')
    contract = await BUIMarketplace.deploy(
      blockContract.address,
      ethers.utils.parseEther('0.01')
    )
    await contract.deployed()
  })

  describe('admin', function () {
    it('disallows a non owner from changing the listing price', async () => {
      const [, acc] = await ethers.getSigners()

      await expect(
        contract.connect(acc).setListingPrice(ethers.utils.parseEther('0.0001'))
      ).to.be.revertedWith('Ownable: caller is not the owne')
    })
  })

  describe('listing a block', function () {
    it('fails to list a block with insufficient funds', async () => {
      await expect(
        contract.listBlock(
          'ipfs://test',
          ethers.utils.parseEther('0.0001'),
          0,
          1,
          true,
          { value: ethers.utils.parseEther('0.001') }
        )
      ).to.be.revertedWith('Insufficient listing funds')
    })

    it('fails to list a block not owned by sender', async () => {
      const [, acc] = await ethers.getSigners()

      await expect(
        contract
          .connect(acc)
          .listBlock(
            'ipfs://test',
            ethers.utils.parseEther('0.0001'),
            0,
            1,
            true,
            { value: ethers.utils.parseEther('0.01') }
          )
      ).to.be.revertedWith('Unauthorized: Not the owner.')
    })

    it('succeeds to list a block', async () => {
      await expect(
        contract.listBlock(
          'ipfs://test',
          ethers.utils.parseEther('0.0001'),
          0,
          1,
          true,
          { value: ethers.utils.parseEther('0.01') }
        )
      )
        .to.emit(contract, 'BUIListingCreated')
        .withArgs(0, true, 1)
    })

    it('returns a listing for tokenId', async () => {
      const listing = await contract.listingForTokenId(1)
      const [acc] = await ethers.getSigners()

      expect(listing.metaDataURI).to.equal('ipfs://test')
      expect(listing.owner).to.equal(acc.address)
      expect(listing.pricePerDay).to.equal(ethers.utils.parseEther('0.0001'))
      expect(listing.price).to.equal(0)
      expect(listing.licensable).to.be.true
    })

    it('returns a list of listings', async () => {
      const [acc] = await ethers.getSigners()
      const listings = await contract.getListings(10, 0)

      expect(listings.length).to.equal(10)
      expect(listings[0].owner).to.equal(acc.address)
    })
  })
})
