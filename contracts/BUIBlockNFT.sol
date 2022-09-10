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

    modifier onlyBlockOwner(bytes32 cid) {
        _checkOwnership(cid, msg.sender);
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

    function updateMetaURI(bytes32 cid, string memory metaURI) external onlyBlockOwner(cid) {
        _blocks[cid].metaURI = metaURI;
    }

    function setDeprecated(bytes32 cid, uint256 deprecateDate) external onlyBlockOwner(cid) {
        _blocks[cid].deprecateDate = deprecateDate;
        emit BUIBlockDeprecated(_tokenizedBlocks[cid]);
    }

    function blockForTokenId(uint256 tokenId) public view returns (bytes32 cid, bytes32 encryptedKey) {
        require(_exists(tokenId), "Token does not exist");

        bytes32 cid = _tokenizedBlocks[tokenId]
        Block storage bui = _blocks[cid];

        return cid, _blocks[cid].encryptedKey;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _blocks[_tokenizedBlocks[tokenId]].metaURI;
    }

    function _checkOwnership(bytes32 cid, address account) internal view virtual {
        if (blocks[cid].owner != account) {
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
