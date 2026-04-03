// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {OutcomeToken} from "./OutcomeToken.sol";

contract PredictionMarket is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE");

    string public marketTitle;
    string public description;
    string public oracleSource;
    uint256 public expiryDate;
    uint256 public confidenceScore;
    uint256 public yesPool;
    uint256 public noPool;
    uint256 public collateralPool;
    bool public resolved;
    bool public disputed;
    bool public outcomeYes;

    OutcomeToken public yesToken;
    OutcomeToken public noToken;

    event PositionBought(address indexed trader, bool yesSide, uint256 collateral, uint256 minted);
    event PositionSold(address indexed trader, bool yesSide, uint256 burned, uint256 collateralReturned);
    event MarketResolved(bool outcomeYes, uint256 confidenceScore);
    event OutcomeDisputed(address indexed disputer, string evidenceUri);
    event RewardsClaimed(address indexed user, uint256 reward);

    constructor(
        address admin,
        string memory title_,
        string memory description_,
        string memory oracleSource_,
        uint256 expiryDate_
    ) {
        marketTitle = title_;
        description = description_;
        oracleSource = oracleSource_;
        expiryDate = expiryDate_;

        yesToken = new OutcomeToken(string.concat("YES-", title_), "pYES", address(this));
        noToken = new OutcomeToken(string.concat("NO-", title_), "pNO", address(this));

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RESOLVER_ROLE, admin);
    }

    function create_market() external pure returns (bool) {
        return true;
    }

    function buy_yes() external payable whenNotPaused nonReentrant {
        require(block.timestamp < expiryDate, "Market expired");
        require(msg.value > 0, "No collateral");
        uint256 minted = _quoteMint(msg.value, true);
        yesPool += msg.value;
        collateralPool += msg.value;
        yesToken.mint(msg.sender, minted);
        emit PositionBought(msg.sender, true, msg.value, minted);
    }

    function buy_no() external payable whenNotPaused nonReentrant {
        require(block.timestamp < expiryDate, "Market expired");
        require(msg.value > 0, "No collateral");
        uint256 minted = _quoteMint(msg.value, false);
        noPool += msg.value;
        collateralPool += msg.value;
        noToken.mint(msg.sender, minted);
        emit PositionBought(msg.sender, false, msg.value, minted);
    }

    function sell_position(bool yesSide, uint256 tokenAmount) external whenNotPaused nonReentrant {
        require(tokenAmount > 0, "Invalid amount");
        uint256 collateralReturned = tokenAmount;
        collateralPool -= collateralReturned;
        if (yesSide) {
            yesToken.burn(msg.sender, tokenAmount);
            yesPool -= collateralReturned;
        } else {
            noToken.burn(msg.sender, tokenAmount);
            noPool -= collateralReturned;
        }
        payable(msg.sender).transfer(collateralReturned);
        emit PositionSold(msg.sender, yesSide, tokenAmount, collateralReturned);
    }

    function get_probability() external view returns (uint256 yesProbabilityBps, uint256 noProbabilityBps) {
        if (collateralPool == 0) {
            return (5000, 5000);
        }
        yesProbabilityBps = (yesPool * 10000) / collateralPool;
        noProbabilityBps = 10000 - yesProbabilityBps;
    }

    function resolve_market(bool outcomeYes_, uint256 confidenceScore_) external onlyRole(RESOLVER_ROLE) {
        require(block.timestamp >= expiryDate, "Not expired");
        require(!resolved, "Already resolved");
        resolved = true;
        outcomeYes = outcomeYes_;
        confidenceScore = confidenceScore_;
        emit MarketResolved(outcomeYes_, confidenceScore_);
    }

    function dispute_outcome(string calldata evidenceUri) external payable whenNotPaused {
        require(resolved, "Not resolved");
        require(msg.value >= 0.01 ether, "Stake too low");
        disputed = true;
        emit OutcomeDisputed(msg.sender, evidenceUri);
    }

    function claim_rewards() external nonReentrant {
        require(resolved, "Not resolved");
        uint256 balance = outcomeYes ? yesToken.balanceOf(msg.sender) : noToken.balanceOf(msg.sender);
        require(balance > 0, "No winning balance");
        uint256 reward = balance;
        if (outcomeYes) {
            yesToken.burn(msg.sender, balance);
        } else {
            noToken.burn(msg.sender, balance);
        }
        payable(msg.sender).transfer(reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _quoteMint(uint256 collateral, bool yesSide) internal view returns (uint256) {
        if (collateralPool == 0) {
            return collateral;
        }
        uint256 sidePool = yesSide ? yesPool : noPool;
        if (sidePool == 0) {
            return collateral;
        }
        return (collateral * collateralPool) / sidePool;
    }
}
