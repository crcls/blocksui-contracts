// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBUIBlockNFT.sol";
import "./Block.sol";

contract BUIBlockNFT is ERC721, Ownable, IBUIBlockNFT {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public publishPrice = 0.1 ether;

    // Published Blocks
    mapping(bytes32 => Block) private _blocks;

    // Token ID => CID
    mapping(uint256 => bytes32) private _tokenizedBlocks;

    modifier onlyBlockOwner(uint256 tokenId) {
        _checkOwnership(tokenId, msg.sender);
        _;
    }

    constructor(uint256 _publishPrice) ERC721("Blocks UI Blocks", "BUIB") {
        publishPrice = _publishPrice;
    }

    function withdraw() external onlyOwner() {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function publish(
        bytes32 cid,
        string memory metaURI
    ) external payable {
        Block storage bui = _blocks[cid];

        // Can't publish the same Block twice
        require(bui.owner == address(0), "This Block is already published");
        // Must pay the fee
        require(msg.value >= publishPrice, "Insufficient funds to publish");

        uint256 tokenId = _tokenIds.current();

        _safeMint(msg.sender, tokenId + 1);

        bui.metaURI = metaURI;
        bui.owner = payable(msg.sender);
        bui.tokenId = tokenId;

        _tokenizedBlocks[tokenId + 1] = cid;
        _tokenIds.increment();

        emit BUIBlockPublished(cid, bui);
    }

    function updateMetaURI(uint256 tokenId, string memory metaURI) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken(tokenId);
        bui.metaURI = metaURI;

        emit BUIBlockMetadataUpdated(tokenId);
    }

    function setDeprecated(uint256 tokenId, uint256 deprecateDate) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken(tokenId);
        bui.deprecateDate = deprecateDate;

        // TODO: use chainlink to auto burn this Block when the deprecateDate is reached.

        emit BUIBlockDeprecated(tokenId);
    }

    function setOrigin(uint256 tokenId, string memory origin) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken(tokenId);

        for (uint i = 0; i < bui.origins.length; i++) {
            bytes32 existingOrigin = keccak256(abi.encodePacked(bui.origins[i]));

            if (existingOrigin == keccak256(abi.encodePacked(origin))) {
                revert("Origin already exists");
            }
        }

        bui.origins.push(origin);
    }

    function removeOrigin(uint256 tokenId, string memory origin) external onlyBlockOwner(tokenId) {
        Block storage bui = _blockForToken(tokenId);

        string[] storage origins = bui.origins;

        for (uint i = 0; i < origins.length; i++) {
            bytes32 matchingOrigin = keccak256(abi.encodePacked(bui.origins[i]));

            if (matchingOrigin == keccak256(abi.encodePacked(origin))) {
                // Overwrite and shift remaining origins
                for (uint j = i; j < origins.length-1; j++) {
                    origins[j] = origins[j+1];
                }
                origins.pop();

                // Save the new origins array
                bui.origins = origins;

                emit BUIBlockOriginRemoved(tokenId, origin);
                break;
            }
        }
    }

    function originAuthorized(bytes32 cid, string calldata origin) external view returns (bool) {
        Block storage bui = _blocks[cid];

        for (uint i = 0; i < bui.origins.length; i++) {
            bytes32 existingOrigin = keccak256(abi.encodePacked(bui.origins[i]));

            if (existingOrigin == keccak256(abi.encodePacked(origin))) {
                return true;
            }
        }

        return false;
    }

    function verifyOwner(bytes32 cid, address owner) external view returns (bool) {
        return _blocks[cid].owner == owner;
    }

    function blockExists(bytes32 cid) external view returns (bool) {
        return _blocks[cid].owner != address(0);
    }

    function blockForToken(uint256 tokenId) external view returns (bytes32 cid, string[] memory origins) {
        Block storage bui = _blockForToken(tokenId);

        return (_tokenizedBlocks[tokenId], bui.origins);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Block storage bui = _blockForToken(tokenId);
        return bui.metaURI;
    }

    function setPublishPrice(uint256 _publishPrice) external onlyOwner {
        publishPrice = _publishPrice;
    }

    function _blockForToken(uint256 tokenId) internal view returns (Block storage) {
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
                        Strings.toString(tokenId)
                    )
                )
            );
        }
    }
}
