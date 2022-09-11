// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Block {
    uint256 tokenId;
    uint256 deprecateDate;
    bytes32 encryptedKey;
    string metaURI;
    address owner;
    string[] origins;
}
