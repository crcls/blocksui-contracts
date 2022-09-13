// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IBUIMarketplace.sol";
import "./IBUIBlockNFT.sol";
import "./License.sol";
import "./Block.sol";
import "./Listing.sol";

contract BUIMarketplace is IBUIMarketplace {

    // Map of tokenIds listed for an account
    mapping(address => uint256[]) private _ownedListings;
    // Map of tokenIds to their Listing
    mapping(uint256 => Listing) private _listings;
    // List of tokenIds for Blocks that are listed.
    uint256[] private _listedTokenIds;

    IBUIBlockNFT private _buiBlockContract;

    uint256 public listingPrice = 0.01 ether;

    constructor(address buiBlockAddress) {
        _buiBlockContract = IBUIBlockNFT(buiBlockAddress);
    }

    function listBlock(
        string memory metaDataURI,
        uint256 pricePerDay,
        uint256 price,
        uint256 tokenId,
        bool licensable
    ) external payable {
        require(msg.value >= listingPrice, "Insufficient funds");
        require(_buiBlockContract.ownerOf(tokenId) == msg.sender, "Unauthorized: Not the owner.");
        require(_listings[tokenId].owner == address(0), "Listing already exists");

        Listing memory listing = Listing(
            metaDataURI,
            payable(msg.sender),
            pricePerDay,
            price,
            licensable
        );

        // Save the listing
        _listings[tokenId] = listing;

        // Store the index of the listing for the sender
        _ownedListings[msg.sender].push(tokenId);

        // Add the tokenId to an array for quick retrieval
        _listedTokenIds.push(tokenId);

        // TODO: If the type is a sale then we also need to approve the transfer

        emit BUIListingCreated(_listedTokenIds.length - 1, licensable, tokenId);
    }

    function listingForTokenId(uint256 tokenId) external view returns (Listing memory listing) {
        listing = _listings[tokenId];
    }

    function getListings(uint256 amount, uint256 page) external view returns (Listing[] memory listings) {
        uint256 max = (amount * page) + amount;

        if (max >= _listedTokenIds.length) {
            max = _listedTokenIds.length;
        }

        uint256 j = 0;
        for (uint256 i = amount * page; i < max; i++) {
            listings[j] = _listings[_listedTokenIds[i]];
            j++;
        }
    }
}
