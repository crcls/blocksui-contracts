// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BUINodeStaking is Ownable {

    uint256 public stakingCost = 0.1 ether;

    struct Node {
        address payable owner;
        uint256 stake;
        bytes4 ip;
    }

    mapping(address => Node) private _nodes;

    event NodeRegistrationChanged(Node node, string status);

    // TODO: add more security to prevent anyone from joining the stake pool and gaining access to the decryption keys in LitProtocol

    constructor(uint256 stakingCost_) {
        stakingCost = stakingCost_;
    }

    function register(bytes4 ip) external payable {
        Node storage node = _nodes[msg.sender];

        if (node.owner == address(0)) {
            node.owner = payable(msg.sender);
        }

        if (node.stake < stakingCost) {
            require(msg.value >= (stakingCost - node.stake), "Not enough stake");
            node.stake += msg.value;
        }

        node.ip = ip;

        emit NodeRegistrationChanged(node, "registered");
    }

    function unregister() external {
        require(_nodes[msg.sender].stake > 0, "No stake found");

        Node storage node = _nodes[msg.sender];
        uint256 stake = node.stake;

        _nodes[msg.sender].stake = 0;
        _nodes[msg.sender].ip = 0;
        payable(msg.sender).transfer(stake);

        emit NodeRegistrationChanged(node, "unregistered");
    }

    function balance(address node) external view returns (uint256) {
        return _nodes[node].stake;
    }

    function verify(address node) external view returns (bool) {
        return _nodes[node].stake > 0 && _nodes[node].ip != 0;
    }

    function setStakingCost(uint256 stakingCost_) external onlyOwner {
        stakingCost = stakingCost_;
    }
}
