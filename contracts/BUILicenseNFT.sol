// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBUIMarketplace.sol";
import "./IBUIBlockNFT.sol";
import "./Block.sol";
import "./License.sol";
import "./Listing.sol";

contract BUILicenseNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IBUIMarketplace private _marketplace;
    IBUIBlockNFT private _blockNFTs;
    mapping(bytes32 => uint256[]) private _licensesForBlock;
    mapping(uint256 => License) private _licenses;

    constructor(address marketplaceAddress, address blocksNFTAddress) ERC721("Blocks UI License", "BUIL") {
        _marketplace = IBUIMarketplace(marketplaceAddress);
        _blockNFTs = IBUIBlockNFT(blocksNFTAddress);
    }

    function purchaseLicense(uint256 blockId, uint256 duration, string memory origin) external payable {
        require(_blockNFTs.ownerOf(blockId) != address(0), "Block does not exist");

        Listing memory listing = _marketplace.listingForTokenId(blockId);
        (bytes32 cid,, string[] memory origins) = _blockNFTs.blockForToken(blockId);

        for (uint i = 0; i < origins.length; i++) {
            bytes32 existingOrigin = keccak256(abi.encodePacked(origins[i]));

            if (existingOrigin == keccak256(abi.encodePacked(origin))) {
                revert("Origin is already authorized");
            }
        }

        require(listing.owner != address(0), "No listing for this Block");
        require(listing.licensable, "Block cannot be licensed");

        // Calculate the cost to license this Block based on days
        uint256 cost = (duration % (60 * 60 * 24)) * listing.pricePerDay;

        require(msg.value >= cost, "Insufficient funds");

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId + 1);
        _tokenIds.increment();

        _licensesForBlock[cid].push(tokenId);
        _licenses[tokenId] = License(
            blockId,
            cid,
            block.timestamp + duration,
            origin,
            msg.sender

        );

        // Transfer the cost to the Block owner
        listing.owner.transfer(cost);
    }

    function verify(bytes32 cid, address owner) public view returns (bool) {
        for (uint i = 0; i < _licensesForBlock[cid].length; i++) {
            License storage license = _licenses[_licensesForBlock[cid][i]];

            if (license.expirationDate <= block.timestamp && license.owner == owner) {
                return true;
            }
        }

        return false;
    }
}