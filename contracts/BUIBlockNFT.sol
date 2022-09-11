// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./Block.sol";

contract BUIBlockNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public publishPrice;

    // Published Blocks
    mapping(bytes32 => Block) private _blocks;

    // Token ID => CID
    mapping(uint256 => bytes32) private _tokenizedBlocks;

    event BUIBlockPublished(
        bytes32 cid,
        Block data
    );

    event BUIBlockDeprecated(uint256 tokenId);
    event BUIBlockMetadataUpdated(uint256 tokenId);
    event BUIBlockOriginRemoved(uint256 tokenId, string origin);

    modifier onlyBlockOwner(uint256 tokenId) {
        _checkOwnership(tokenId, msg.sender);
        _;
    }

    constructor(uint256 _publishPrice) ERC721("Blocks UI Blocks", "BUIB") {
        publishPrice = _publishPrice;
    }

    function publish(
        bytes32 cid,
        bytes32 encryptedKey,
        string memory metaURI,
    ) external payable {
        Block storage bui = _blocks[cid];

        // Can't publish the same Block twice
        require(bui.owner == address(0), "This Block is already published");
        // Must pay the fee
        require(msg.value >= publishPrice, "Insufficient funds to publish");

        uint256 tokenId = _tokenIds.current();

        _safeMint(msg.sender, tokenId + 1);

        bui.encryptedKey = encryptedKey;
        bui.metaURI = metaURI;
        bui.owner = payable(msg.sender);
        bui.tokenId = tokenId;

        _tokenizedBlocks[tokenId] = cid;
        _tokenIds.increment();

        emit BUIBlockPublished(cid, bui);
    }

    function updateMetaURI(uint256 tokenId, string memory metaURI) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken[tokenId];
        bui.metaURI = metaURI;

        emit BUIBlockMetadataUpdated(tokenId);
    }

    function setDeprecated(uint256 tokenId, uint256 deprecateDate) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken[tokenId];
        bui.deprecateDate = deprecateDate;

        // TODO: use chainlink to auto burn this Block when the deprecateDate is reached.

        emit BUIBlockDeprecated(tokenId);
    }

    function setOrigin(uint256 tokenId, string memory origin) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken(tokenId);

        for (uint i = 0; i < bui.origins.length; i++) {
            if (bui.origins[i] == origin) {
                revert("Origin already exists");
            }
        }

        bui.origins.push(origin)
    }

    function removeOrigin(uint256 tokenId, string memory origin) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken(tokenId);

        string[] origins = bui.origins;

        for (uint i = 0; i < origins.length; i++) {
            if (origins[i] == origin) {
                // Overwrite and shift remaining origins
                for (uint j = i; j < origins.length-1; j++) {
                    origins[j] = origins[j+1];
                }
                payees.pop();

                // Save the new origins array
                bui.origins = origins;

                emit BUIBlockOriginRemoved(tokenId, origin);
                break;
            }
        }
    }

    function blockForToken(uint256 tokenId) public view returns (bytes32 cid, bytes32 encryptedKey, string[] origins) {
        Block storage bui = _blockForToken(tokenId);

        return _tokenizedBlock[tokenId], bui.encryptedKey, bui.origins;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Block storage bui = _blockForToken(tokenId);
        return bui.metaURI;
    }

    function setPublishPrice(uint256 _publishPrice) external onlyOwner {
        publishPrice = _publishPrice;
    }

    function _blockForToken(uint256 tokenId) internal view returns (bytes32, Block) {
        require(_exists(tokenId), "Token does not exist");
        return _blocks[_tokenizedBlocks[tokenId]];
    }

    function _checkOwnership(uint256 tokenId, address account) internal view {
        if (ownerOf(tokenId) != account) {
            revert(
                string(
                    abi.encodePacked(
                        "BlocksUI: account ",
                        Strings.toHexString(account),
                        " is not the owner of ",
                        cid
                    )
                )
            );
        }
    }
}
