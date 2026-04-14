// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract AETHToken is ERC20, AccessControl {
    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");

    uint256 public immutable maxSupply;
    uint256 public totalStaked;
    uint256 public rewardPool;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public pendingRewards;

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event RewardFunded(address indexed from, uint256 amount);
    event RewardNotified(address indexed account, uint256 amount);
    event RewardClaimed(address indexed account, uint256 amount);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);

    constructor(address admin, address treasury, uint256 maxSupply_) ERC20("AetherPredict", "AETH") {
        require(admin != address(0), "Invalid admin");
        require(treasury != address(0), "Invalid treasury");
        require(maxSupply_ > 0, "Invalid max supply");

        maxSupply = maxSupply_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(TOKEN_ADMIN_ROLE, admin);
        _grantRole(REWARD_DISTRIBUTOR_ROLE, admin);

        _mint(treasury, maxSupply_);
    }

    function mint(address to, uint256 amount) external onlyRole(TOKEN_ADMIN_ROLE) {
        _mintWithCap(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount is zero");
        _transfer(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount is zero");
        require(stakedBalance[msg.sender] >= amount, "Insufficient stake");

        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        _transfer(address(this), msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    function fundRewards(uint256 amount) external onlyRole(REWARD_DISTRIBUTOR_ROLE) {
        require(amount > 0, "Amount is zero");
        _transfer(msg.sender, address(this), amount);
        rewardPool += amount;
        emit RewardFunded(msg.sender, amount);
    }

    function notifyReward(address account, uint256 amount) external onlyRole(REWARD_DISTRIBUTOR_ROLE) {
        require(account != address(0), "Invalid account");
        require(amount > 0, "Amount is zero");
        require(rewardPool >= amount, "Reward pool exhausted");

        rewardPool -= amount;
        pendingRewards[account] += amount;

        emit RewardNotified(account, amount);
    }

    function claimRewards() external {
        uint256 reward = pendingRewards[msg.sender];
        require(reward > 0, "No rewards");

        pendingRewards[msg.sender] = 0;
        _transfer(address(this), msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function vote(uint256 proposalId, bool support) external {
        uint256 weight = stakedBalance[msg.sender];
        require(weight > 0, "No stake");
        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    function _mintWithCap(address to, uint256 amount) internal {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _mint(to, amount);
    }
}
