// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {OutcomeToken} from "./OutcomeToken.sol";

interface IGovernanceStaking {
    function submitDisputeFromMarket(address disputer, address market, string calldata evidenceUri, uint256 stakeAmount)
        external
        returns (uint256 disputeId);
}

contract PredictionMarket is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");
    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DISPUTE_ROLE = keccak256("DISPUTE_ROLE");

    string public marketTitle;
    string public description;
    string public oracleSource;

    address public collateralToken;
    address public governanceStaking;
    address public liquidityVault;
    address public feeCollector;

    uint256 public expiryDate;
    uint256 public confidenceScore;
    uint256 public yesPool;
    uint256 public noPool;
    uint256 public collateralPool;

    uint256 public disputeWindowSeconds;
    uint256 public minDisputeStake;
    uint256 public protocolFeeBps;

    bool public settlementProposed;
    bool public resolved;
    bool public disputed;
    bool public outcomeYes;
    bool public proposedOutcomeYes;

    uint256 public proposedConfidenceScore;
    uint256 public proposedAt;
    uint256 public disputeDeadline;
    uint256 public winningSupplySnapshot;
    uint256 public redeemableCollateralPool;

    string public resolutionEvidenceUri;

    OutcomeToken public yesToken;
    OutcomeToken public noToken;

    event PositionBought(address indexed trader, bool yesSide, uint256 collateral, uint256 minted);
    event PositionSold(address indexed trader, bool yesSide, uint256 burned, uint256 collateralReturned);
    event SettlementProposed(bool outcomeYes, uint256 confidenceScore, string evidenceUri, uint256 disputeDeadline);
    event MarketResolved(bool outcomeYes, uint256 confidenceScore);
    event OutcomeDisputed(address indexed disputer, string evidenceUri);
    event DisputeFinalized(bool finalOutcomeYes, uint256 confidenceScore, string reason);
    event RewardsClaimed(address indexed user, uint256 reward);
    event OutcomeTokensInitialized(address indexed yesToken, address indexed noToken);

    constructor(
        address admin,
        address factory,
        address collateralToken_,
        string memory title_,
        string memory description_,
        string memory oracleSource_,
        uint256 expiryDate_,
        uint256 disputeWindowSeconds_,
        uint256 minDisputeStake_,
        uint256 protocolFeeBps_,
        address feeCollector_,
        address governanceStaking_,
        address liquidityVault_
    ) {
        require(admin != address(0), "Invalid admin");
        require(factory != address(0), "Invalid factory");
        require(expiryDate_ > block.timestamp, "Invalid expiry");
        require(protocolFeeBps_ <= 1_000, "Fee too high");

        marketTitle = title_;
        description = description_;
        oracleSource = oracleSource_;

        collateralToken = collateralToken_;
        governanceStaking = governanceStaking_;
        liquidityVault = liquidityVault_;
        feeCollector = feeCollector_ == address(0) ? admin : feeCollector_;

        expiryDate = expiryDate_;
        disputeWindowSeconds = disputeWindowSeconds_;
        minDisputeStake = minDisputeStake_;
        protocolFeeBps = protocolFeeBps_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MARKET_ADMIN_ROLE, admin);
        _grantRole(RESOLVER_ROLE, admin);
        _grantRole(DISPUTE_ROLE, admin);

        _grantRole(FACTORY_ROLE, factory);
        _grantRole(RESOLVER_ROLE, factory);
    }

    function initializeOutcomeTokens(address yesToken_, address noToken_) external onlyRole(FACTORY_ROLE) {
        require(address(yesToken) == address(0) && address(noToken) == address(0), "Already initialized");
        require(yesToken_ != address(0) && noToken_ != address(0), "Invalid tokens");

        yesToken = OutcomeToken(yesToken_);
        noToken = OutcomeToken(noToken_);

        emit OutcomeTokensInitialized(yesToken_, noToken_);
    }

    function setGovernanceStaking(address governanceStaking_) external onlyRole(MARKET_ADMIN_ROLE) {
        governanceStaking = governanceStaking_;
    }

    function setLiquidityVault(address liquidityVault_) external onlyRole(MARKET_ADMIN_ROLE) {
        liquidityVault = liquidityVault_;
    }

    function setFeeCollector(address feeCollector_) external onlyRole(MARKET_ADMIN_ROLE) {
        require(feeCollector_ != address(0), "Invalid fee collector");
        feeCollector = feeCollector_;
    }

    function setProtocolFeeBps(uint256 protocolFeeBps_) external onlyRole(MARKET_ADMIN_ROLE) {
        require(protocolFeeBps_ <= 1_000, "Fee too high");
        protocolFeeBps = protocolFeeBps_;
    }

    function setDisputeWindow(uint256 disputeWindowSeconds_) external onlyRole(MARKET_ADMIN_ROLE) {
        disputeWindowSeconds = disputeWindowSeconds_;
    }

    function setMinDisputeStake(uint256 minDisputeStake_) external onlyRole(MARKET_ADMIN_ROLE) {
        minDisputeStake = minDisputeStake_;
    }

    function buyYes(uint256 collateralAmount) external payable whenNotPaused nonReentrant {
        _buyPosition(true, collateralAmount);
    }

    function buyNo(uint256 collateralAmount) external payable whenNotPaused nonReentrant {
        _buyPosition(false, collateralAmount);
    }

    function buy_yes() external payable whenNotPaused nonReentrant {
        _buyPosition(true, msg.value);
    }

    function buy_no() external payable whenNotPaused nonReentrant {
        _buyPosition(false, msg.value);
    }

    function sellPosition(bool yesSide, uint256 tokenAmount) public whenNotPaused nonReentrant {
        require(!resolved && !settlementProposed, "Settlement in progress");
        require(tokenAmount > 0, "Invalid amount");

        if (yesSide) {
            yesToken.burnFrom(msg.sender, tokenAmount);
            yesPool -= tokenAmount;
        } else {
            noToken.burnFrom(msg.sender, tokenAmount);
            noPool -= tokenAmount;
        }

        collateralPool -= tokenAmount;
        _transferCollateralOut(msg.sender, tokenAmount);

        emit PositionSold(msg.sender, yesSide, tokenAmount, tokenAmount);
    }

    function sell_position(bool yesSide, uint256 tokenAmount) external {
        sellPosition(yesSide, tokenAmount);
    }

    function settleYes(uint256 confidenceScore_, string calldata evidenceUri) external onlyRole(RESOLVER_ROLE) {
        _proposeSettlement(true, confidenceScore_, evidenceUri);
    }

    function settleNo(uint256 confidenceScore_, string calldata evidenceUri) external onlyRole(RESOLVER_ROLE) {
        _proposeSettlement(false, confidenceScore_, evidenceUri);
    }

    function resolve_market(bool outcomeYes_, uint256 confidenceScore_) external onlyRole(RESOLVER_ROLE) {
        _proposeSettlement(outcomeYes_, confidenceScore_, "");
        _finalizeResolution(outcomeYes_, confidenceScore_, "legacy-immediate");
    }

    function finalizeSettlement() public {
        require(settlementProposed, "No proposal");
        require(!resolved, "Already resolved");
        require(!disputed, "Disputed");
        require(block.timestamp >= disputeDeadline, "Dispute window open");

        _finalizeResolution(proposedOutcomeYes, proposedConfidenceScore, "window-finalized");
    }

    function finalizeDispute(bool finalOutcomeYes, uint256 confidenceScore_, string calldata reason) external onlyRole(DISPUTE_ROLE) {
        require(settlementProposed, "No proposal");
        require(disputed, "Not disputed");
        require(!resolved, "Already resolved");

        _finalizeResolution(finalOutcomeYes, confidenceScore_, reason);
        emit DisputeFinalized(finalOutcomeYes, confidenceScore_, reason);
    }

    function disputeOutcome(string calldata evidenceUri, uint256 stakeAmount) public payable whenNotPaused nonReentrant {
        require(settlementProposed, "No proposal");
        require(!resolved, "Already resolved");
        require(block.timestamp < disputeDeadline, "Dispute closed");

        if (governanceStaking != address(0) && stakeAmount > 0) {
            IGovernanceStaking(governanceStaking).submitDisputeFromMarket(msg.sender, address(this), evidenceUri, stakeAmount);
        } else {
            require(msg.value >= minDisputeStake, "Stake too low");
        }

        disputed = true;

        emit OutcomeDisputed(msg.sender, evidenceUri);
    }

    function dispute_outcome(string calldata evidenceUri) external payable {
        disputeOutcome(evidenceUri, 0);
    }

    function claimWinnings() public nonReentrant {
        require(resolved, "Not resolved");

        OutcomeToken winningToken = outcomeYes ? yesToken : noToken;
        uint256 winningBalance = winningToken.balanceOf(msg.sender);
        require(winningBalance > 0, "No winning balance");
        require(redeemableCollateralPool >= winningBalance, "Insufficient redeemable pool");

        winningToken.burnFrom(msg.sender, winningBalance);

        redeemableCollateralPool -= winningBalance;
        collateralPool -= winningBalance;

        _transferCollateralOut(msg.sender, winningBalance);

        emit RewardsClaimed(msg.sender, winningBalance);
    }

    function claim_rewards() external {
        claimWinnings();
    }

    function getProbability() external view returns (uint256 yesProbabilityBps, uint256 noProbabilityBps) {
        if (collateralPool == 0) {
            return (5000, 5000);
        }
        yesProbabilityBps = (yesPool * 10000) / collateralPool;
        noProbabilityBps = 10000 - yesProbabilityBps;
    }

    function get_probability() external view returns (uint256 yesProbabilityBps, uint256 noProbabilityBps) {
        return this.getProbability();
    }

    function create_market() external pure returns (bool) {
        return true;
    }

    function pause() external {
        require(hasRole(MARKET_ADMIN_ROLE, msg.sender) || hasRole(FACTORY_ROLE, msg.sender), "Missing role");
        _pause();
    }

    function unpause() external {
        require(hasRole(MARKET_ADMIN_ROLE, msg.sender) || hasRole(FACTORY_ROLE, msg.sender), "Missing role");
        _unpause();
    }

    function _buyPosition(bool yesSide, uint256 collateralAmount) internal {
        require(block.timestamp < expiryDate, "Market expired");
        require(!resolved && !settlementProposed, "Settlement in progress");
        require(address(yesToken) != address(0) && address(noToken) != address(0), "Outcome tokens not initialized");

        uint256 received = _transferCollateralIn(collateralAmount);
        require(received > 0, "No collateral");

        uint256 fee = (received * protocolFeeBps) / 10_000;
        uint256 netCollateral = received - fee;

        if (yesSide) {
            yesPool += netCollateral;
            yesToken.mint(msg.sender, netCollateral);
        } else {
            noPool += netCollateral;
            noToken.mint(msg.sender, netCollateral);
        }

        collateralPool += netCollateral;

        if (fee > 0) {
            _transferFee(fee);
        }

        emit PositionBought(msg.sender, yesSide, netCollateral, netCollateral);
    }

    function _proposeSettlement(bool outcomeYes_, uint256 confidenceScore_, string memory evidenceUri) internal {
        require(block.timestamp >= expiryDate, "Not expired");
        require(!resolved, "Already resolved");
        require(!settlementProposed, "Already proposed");

        settlementProposed = true;
        disputed = false;
        proposedOutcomeYes = outcomeYes_;
        proposedConfidenceScore = confidenceScore_;
        proposedAt = block.timestamp;
        disputeDeadline = block.timestamp + disputeWindowSeconds;
        resolutionEvidenceUri = evidenceUri;

        emit SettlementProposed(outcomeYes_, confidenceScore_, evidenceUri, disputeDeadline);

        if (disputeWindowSeconds == 0) {
            _finalizeResolution(outcomeYes_, confidenceScore_, "instant");
        }
    }

    function _finalizeResolution(bool finalOutcomeYes, uint256 finalConfidence, string memory) internal {
        require(!resolved, "Already resolved");

        resolved = true;
        settlementProposed = false;
        outcomeYes = finalOutcomeYes;
        confidenceScore = finalConfidence;

        OutcomeToken winningToken = finalOutcomeYes ? yesToken : noToken;
        uint256 winningSupply = winningToken.totalSupply();
        winningSupplySnapshot = winningSupply;
        redeemableCollateralPool = winningSupply;

        if (collateralPool > redeemableCollateralPool) {
            uint256 excess = collateralPool - redeemableCollateralPool;
            collateralPool = redeemableCollateralPool;
            _transferCollateralOut(_feeDestination(), excess);
        }

        emit MarketResolved(finalOutcomeYes, finalConfidence);
    }

    function _feeDestination() internal view returns (address) {
        if (liquidityVault != address(0)) {
            return liquidityVault;
        }
        return feeCollector;
    }

    function _transferFee(uint256 amount) internal {
        address destination = _feeDestination();
        if (destination == address(0) || amount == 0) {
            return;
        }

        if (collateralToken == address(0)) {
            (bool ok,) = payable(destination).call{value: amount}("");
            require(ok, "Fee transfer failed");
        } else {
            IERC20(collateralToken).safeTransfer(destination, amount);
        }
    }

    function _transferCollateralIn(uint256 amount) internal returns (uint256 transferred) {
        if (collateralToken == address(0)) {
            transferred = msg.value;
            require(transferred > 0, "No native collateral");
            if (amount > 0) {
                require(amount == transferred, "Amount mismatch");
            }
            return transferred;
        }

        require(msg.value == 0, "Unexpected native value");
        require(amount > 0, "No token collateral");

        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    function _transferCollateralOut(address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (collateralToken == address(0)) {
            (bool ok,) = payable(to).call{value: amount}("");
            require(ok, "Native transfer failed");
        } else {
            IERC20(collateralToken).safeTransfer(to, amount);
        }
    }
}
