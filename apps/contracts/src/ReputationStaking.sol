// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";

contract ReputationStaking is AccessControl, Pausable {
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public reputationScore;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ReputationAdjusted(address indexed user, uint256 newScore);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function stake() external payable whenNotPaused {
        stakes[msg.sender] += msg.value;
        reputationScore[msg.sender] += msg.value / 1e15;
        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external whenNotPaused {
        require(stakes[msg.sender] >= amount, "Insufficient stake");
        stakes[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

    function adjustReputation(address user, uint256 newScore) external onlyRole(DEFAULT_ADMIN_ROLE) {
        reputationScore[user] = newScore;
        emit ReputationAdjusted(user, newScore);
    }
}
