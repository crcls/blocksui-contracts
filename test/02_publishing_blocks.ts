import { Contract } from '@ethersproject/contracts'
import { expect } from 'chai'
import { ethers } from 'hardhat'

import {
  getBytes32FromIpfsHash,
  getIpfsHashFromBytes32,
} from '../helpers/bytes'

const ipfsHash = 'QmWmyoMoctfbAaiEs2G46gpeUmhqFRDW6KWo64y5r581Vz'
const cid = getBytes32FromIpfsHash(ipfsHash)

describe('BUIBlockNFT', function () {
  let contract: Contract | undefined

  before(async () => {
    const BUIBlockNFT = await ethers.getContractFactory('BUIBlockNFT')
    contract = await BUIBlockNFT.deploy(ethers.utils.parseEther('1'))
    await contract.deployed()
  })

  describe('Non-existing Block', function () {
    it('fails to update a non-existing block', async () => {
      await expect(contract.updateMetaURI(1, 'test')).to.be.revertedWith(
        'ERC721: invalid token ID'
      )
      await expect(
        contract.setDeprecated(1, Math.round(Date.now() / 1000))
      ).to.be.revertedWith('ERC721: invalid token ID')
      await expect(contract.setOrigin(1, 'test')).to.be.revertedWith(
        'ERC721: invalid token ID'
      )
      await expect(contract.removeOrigin(1, 'test')).to.be.revertedWith(
        'ERC721: invalid token ID'
      )
    })

    it('fails to fetch data for non-existing block', async () => {
      await expect(contract.blockForToken(1)).to.be.revertedWith(
        'Token does not exist'
      )
      await expect(contract.tokenURI(1)).to.be.revertedWith(
        'Token does not exist'
      )
    })

    it('fails to find a block by non-existing CID', async () => {
      expect(await contract.blockExists(cid)).to.be.false
    })
  })

  describe('Publishing', function () {
    it('fails with insufficient funds', async () => {
      await expect(
        contract.publish(cid, 'ipfs://test', {
          value: ethers.utils.parseEther('0.5'),
        })
      ).to.be.revertedWith('Insufficient funds to publish')
    })

    it('succeeds to publish a block', async () => {
      const [acc] = await ethers.getSigners()

      const tx = contract.publish(cid, 'ipfs://test', {
        value: ethers.utils.parseEther('1'),
      })

      await expect(tx).to.not.be.reverted
      expect(tx).to.changeEtherBalance(acc, '-1')
    })

    it('succeeds in finding the new token by cid', async () => {
      const [acc] = await ethers.getSigners()
      expect(await contract.blockExists(cid)).to.be.true
      expect(await contract.ownerOfBlock(cid, acc.address)).to.be.true
    })

    it('prevents other account from updating the Block meta', async () => {
      const [, acc] = await ethers.getSigners()
      const revertMsg = `BlocksUI: account ${acc.address.toLowerCase()} is not the owner of 1`

      await expect(
        contract.connect(acc).updateMetaURI(1, 'test')
      ).to.be.revertedWith(revertMsg)
      await expect(
        contract.connect(acc).setDeprecated(1, Math.round(Date.now() / 1000))
      ).to.be.revertedWith(revertMsg)
      await expect(
        contract.connect(acc).setOrigin(1, 'test')
      ).to.be.revertedWith(revertMsg)
      await expect(
        contract.connect(acc).removeOrigin(1, 'test')
      ).to.be.revertedWith(revertMsg)
    })

    it('allows the owner to update the Block meta', async () => {
      await expect(contract.updateMetaURI(1, 'test')).to.not.be.reverted
      await expect(contract.setDeprecated(1, Math.round(Date.now() / 1000))).to
        .not.be.reverted
      await expect(contract.setOrigin(1, 'test')).to.not.be.reverted
      await expect(contract.removeOrigin(1, 'test')).to.not.be.reverted
    })

    it('returns the proper block values', async () => {
      await contract.setOrigin(1, 'http://example.com')
      const [cid, origins] = await contract.blockForToken(1)

      expect(getIpfsHashFromBytes32(cid)).to.equal(ipfsHash)
      expect(origins.length).to.equal(1)
      expect(origins[0]).to.equal('http://example.com')
    })
  })
})
