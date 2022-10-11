import { Wallet } from 'ethers'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

import { customAlphabet } from 'nanoid'
const createId = customAlphabet('1234567890abcdef', 10)

interface AuthSig {
  address: string
  derivedVia: string
  sig: string
  signedMessage: string
}

function generateMessage(address: string, chainId: number): string {
  return `blocksui.xyz wants you to sign in with your Ethereum account:
${address}


URI: https://blocksui.xyz
Version: 1
Chain ID: ${chainId}
Nonce: ${createId()}
Issued At: ${new Date().toISOString()}`
}

export async function createAuthSig(
  privKey: string,
  hre: HardhatRuntimeEnvironment,
  chainId: number
): AuthSig {
  const wallet = new Wallet(privKey, hre.provider)

  const signedMessage = generateMessage(wallet.address, chainId)

  const sig = await wallet.signMessage(signedMessage)

  console.log(
    'Recovered Address: ',
    ethers.utils.verifyMessage(signedMessage, sig)
  )

  return {
    address: wallet.address,
    derivedVia: 'ethers.signer.signMessage',
    sig,
    signedMessage,
  }
}
