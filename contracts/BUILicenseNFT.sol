// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IBUIMarketplace.sol";
import "./IBUIBlockNFT.sol";
import "./Block.sol";
import "./License.sol";
import "./Listing.sol";

contract BUILicenseNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IBUIMarketplace private _marketplace;
    IBUIBlockNFT private _blockNFTs;
    mapping(bytes32 => uint256[]) private _licensesForBlock;
    mapping(uint256 => License) private _licenses;

    event BUILicensePurchased(uint256 tokenId, uint256 duration, bytes32 cid);

    constructor(address marketplaceAddress, address blocksNFTAddress) ERC721("Blocks UI License", "BUIL") {
        _marketplace = IBUIMarketplace(marketplaceAddress);
        _blockNFTs = IBUIBlockNFT(blocksNFTAddress);
    }

    function withdraw() external onlyOwner() {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function purchaseLicense(uint256 blockId, uint256 duration, bytes32 origin) external payable {
        require(_blockNFTs.ownerOf(blockId) != address(0), "Block does not exist");
        require(_blockNFTs.ownerOf(blockId) != msg.sender, "License not required for Block owner");

        Listing memory listing = _marketplace.listingForTokenId(blockId);
        bytes32 cid = _blockNFTs.blockForToken(blockId);

        require(listing.owner != address(0), "No listing for this Block");
        require(listing.licensable, "Block cannot be licensed");

        // Calculate the cost to license this Block based on days
        uint256 cost = Math.ceilDiv(duration, 86400) * listing.pricePerDay;

        require(msg.value >= cost, "Insufficient funds for license");

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId + 1);
        _tokenIds.increment();

        _licensesForBlock[cid].push(tokenId);
        _licenses[tokenId] = License(
            blockId,
            cid,
            block.timestamp + duration,
            msg.sender,
            origin
        );

        // TODO: use chainlink to auto burn this license when the expiration date is past

        // Transfer the cost to the Block owner
        listing.owner.transfer(cost);

        emit BUILicensePurchased(tokenId, duration, cid);
    }

    function verifyOwner(bytes32 cid, address owner) public view returns (bool) {
        for (uint i = 0; i < _licensesForBlock[cid].length; i++) {
            License storage license = _licenses[_licensesForBlock[cid][i]];

            if (license.expirationDate <= block.timestamp && license.owner == owner) {
                return true;
            }
        }

        return false;
    }

    function verifyOrigin(uint256 tokenId, bytes32 origin) public view returns (bool) {
        return _licenses[tokenId].origin == origin;
    }
}
