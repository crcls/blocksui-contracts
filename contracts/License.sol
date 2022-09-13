// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct License {
    uint blockId;
    bytes32 cid;
    uint256 expirationDate;
    string origin;
    address owner;
}
