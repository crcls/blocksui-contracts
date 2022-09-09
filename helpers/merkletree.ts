import { ethers } from 'ethers'
import { MerkleTree } from 'merkletreejs'

const { keccak256 } = ethers.utils

interface MerkleData {
  root: string,
  proof: string[]
}

export function getMerkleData(sender: string, accounts: string[]): MerkleData {
  const leaves = accounts.map(account => keccak256(account))
  const tree = new MerkleTree(leaves, keccak256, { sort: true })
  const root = tree.getHexRoot()
  const proof = tree.getHexProof(keccak256(sender))

  return { root, proof }
}
