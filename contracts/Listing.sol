// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Listing {
    string metaDataURI;
    address payable owner;
    uint256 pricePerDay;
    uint256 price;
    bool licensable;
}
