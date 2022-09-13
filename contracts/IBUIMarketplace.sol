// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Listing.sol";

interface IBUIMarketplace {
    event BUIListingCreated(uint256 id, bool licensable, uint256 tokenId);

    function listBlock(
        string memory metaDataURI,
        uint256 pricePerDay,
        uint256 price,
        uint256 tokenId,
        bool licensable
    ) external payable;

    function listingForTokenId(uint256 tokenId) external view returns (Listing memory);

    function getListings(uint256 amount, uint256 page) external view returns (Listing[] memory);
}
