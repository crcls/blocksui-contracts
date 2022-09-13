// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Block.sol";

interface IBUIBlockNFT is IERC721 {
    event BUIBlockPublished(
        bytes32 cid,
        Block data
    );

    event BUIBlockDeprecated(uint256 tokenId);
    event BUIBlockMetadataUpdated(uint256 tokenId);
    event BUIBlockOriginRemoved(uint256 tokenId, string origin);

    function blockForToken(uint256 tokenId) external view returns (bytes32 cid, string memory encryptedKey, string[] memory origins);

    function ownerOfBlock(bytes32 cid, address owner) external view returns (bool);

    function blockExists(bytes32 cid) external view returns (bool);
}
