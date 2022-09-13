// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BUINodeStaking is Ownable {

    uint256 private _stakingCost = 0.1 ether;

    mapping(address => uint256) private _stake;

    // TODO: add more security to prevent anyone from joining the stake pool and gaining access to the decryption keys in LitProtocol

    constructor(uint256 stakingCost) {
        _stakingCost = stakingCost;
    }

    function register() external payable {
        require(msg.value >= _stakingCost, "Insufficient funds");
        require(_stake[msg.sender] == 0, "Already registered");

        bytes32 hashedNode = keccak256(abi.encodePacked(msg.sender));
        _hashedNodes.push(hashedNode);
        _stake[msg.sender] += msg.value;
    }

    function unregister() external {
        require(_stake[msg.sender] > 0, "No stake found");

        bytes32 hashedNode = keccak256(abi.encodePacked(msg.sender));

        bool nodeFound = false;
        for (uint i = 0; i < _hashedNodes.length; i++) {
            if (_hashedNodes[i] == hashedNode) {
                nodeFound = true;
                for (uint j = i; j < _hashedNodes.length-1; j++) {
                    _hashedNodes[j] = _hashedNodes[j+1];
                }

                _hashedNodes.pop();
            }
        }

        require(nodeFound, "Node not found");
        payable(msg.sender).transfer(_stake[msg.sender]);
    }

    function verify(address node) external view returns (bool) {
        return _stake[node] > 0;
    }

    function setStakingCost(uint256 stakingCost) external onlyOwner {
        _stakingCost = stakingCost;
    }
}
