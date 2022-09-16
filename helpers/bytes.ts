import mh from 'multihashes'
import { ethers } from 'ethers'

export function getBytes32FromIpfsHash(cid: string): string {
  const bytes = mh.fromB58String(cid)
  const hex = mh.toHexString(bytes.slice(2))

  return `0x${hex}`
}

export function getIpfsHashFromBytes32(bytes32: string): string {
  const hex = '1220' + bytes32.substring(2)
  const bytes = mh.fromHexString(hex)
  return mh.toB58String(bytes)
}

export function bytes4ForIpString(ip: string): string {
  const data = Uint8Array.from(ip.split('.'), Number.parseInt)
  return ethers.utils.hexConcat(data)
}
