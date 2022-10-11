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

    mapping(address => Node) private _nodeByAddress;
    Node[] private _nodes;

    event NodeRegistrationChanged(Node node, string status);

    // TODO: add more security to prevent anyone from joining the stake pool and gaining access to the decryption keys in LitProtocol

    constructor(uint256 stakingCost_) {
        stakingCost = stakingCost_;
    }

    function withdraw() external onlyOwner() {
        uint256 bal = address(this).balance;
        uint256 staked = totalStaked();

        if (bal > staked) {
            payable(owner()).transfer(bal - staked);
        }
    }

    function totalStaked() public view returns (uint256 total) {
        for (uint i = 0; i < _nodes.length; i++) {
            total += _nodes[i].stake;
        }
    }

    function register(bytes4 ip) external payable {
        Node storage node = _nodeByAddress[msg.sender];

        if (node.owner == address(0)) {
            node.owner = payable(msg.sender);
        }

        if (node.stake < stakingCost) {
            require(msg.value >= (stakingCost - node.stake), "Not enough stake");
            node.stake += msg.value;
        }

        node.ip = ip;
        _nodes.push(node);

        emit NodeRegistrationChanged(node, "registered");
    }

    function unregister() external {
        require(_nodeByAddress[msg.sender].stake > 0, "No stake found");

        Node storage node = _nodeByAddress[msg.sender];
        uint256 stake = node.stake;

        for (uint i = 0; i < _nodes.length; i++) {
            if (_nodes[i].owner == msg.sender) {
                for (uint j = i; j < _nodes.length-1; j++) {
                    _nodes[j] = _nodes[j+1];
                }
                _nodes.pop();
            }
        }

        _nodeByAddress[msg.sender].stake = 0;
        _nodeByAddress[msg.sender].ip = 0;
        payable(msg.sender).transfer(stake);

        emit NodeRegistrationChanged(node, "unregistered");
    }

    function balance(address node) external view returns (uint256) {
        return _nodeByAddress[node].stake;
    }

    function verify(address node) external view returns (bool) {
        return _nodeByAddress[node].stake > 0 && _nodeByAddress[node].ip != 0;
    }

    function setStakingCost(uint256 stakingCost_) external onlyOwner {
        stakingCost = stakingCost_;
    }
}
