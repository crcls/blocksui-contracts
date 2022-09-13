import mh from 'multihashes'

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
