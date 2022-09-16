// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BUINodeStaking is Ownable {

    uint256 private _stakingCost = 0.1 ether;

    struct Node {
        address payable owner;
        uint256 stake;
        bytes4 ip;
    }

    mapping(address => Node) private _nodes;

    event NodeRegistered(Node node);

    // TODO: add more security to prevent anyone from joining the stake pool and gaining access to the decryption keys in LitProtocol

    constructor(uint256 stakingCost) {
        _stakingCost = stakingCost;
    }

    function register(bytes4 ip) external payable {
        Node storage node = _nodes[msg.sender];

        if (node.owner == address(0)) {
            node.owner = payable(msg.sender);
        }

        if (node.stake < _stakingCost) {
            require(msg.value >= (_stakingCost - node.stake), "Not enough stake");
            node.stake += msg.value;
        }

        node.ip = ip;
    }

    function unregister() external {
        require(_nodes[msg.sender].stake > 0, "No stake found");

        _nodes[msg.sender].stake = 0;
        _nodes[msg.sender].ip = 0;
        payable(msg.sender).transfer(_nodes[msg.sender].stake);
    }

    function balance() external view returns (uint256) {
        return _nodes[msg.sender].stake;
    }

    function verify(address node) external view returns (bool) {
        return _nodes[node].stake > 0 && _nodes[node].ip != 0;
    }

    function setStakingCost(uint256 stakingCost) external onlyOwner {
        _stakingCost = stakingCost;
    }
}
