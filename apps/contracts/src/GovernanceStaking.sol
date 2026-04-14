// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract GovernanceStaking is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant STAKING_ADMIN_ROLE = keccak256("STAKING_ADMIN_ROLE");
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");
    bytes32 public constant MARKET_ROLE = keccak256("MARKET_ROLE");
    bytes32 public constant MARKET_REGISTRAR_ROLE = keccak256("MARKET_REGISTRAR_ROLE");
    bytes32 public constant DISPUTE_ADMIN_ROLE = keccak256("DISPUTE_ADMIN_ROLE");

    struct Dispute {
        uint256 id;
        address market;
        address proposer;
        string evidenceUri;
        uint256 stakeAmount;
        uint256 createdAt;
        uint256 yesVotes;
        uint256 noVotes;
        bool resolved;
        bool accepted;
    }

    IERC20 public immutable aethToken;
    address public treasury;

    uint256 public totalStaked;
    uint256 public accRewardsPerShareWad;
    uint256 public nextDisputeId = 1;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public pendingRewards;

    mapping(uint256 => Dispute) public disputes;
    mapping(address => uint256[]) public disputeHistory;
    mapping(uint256 => mapping(address => bool)) public disputeVoted;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsFunded(uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event MarketRegistered(address indexed market);
    event DisputeSubmitted(uint256 indexed disputeId, address indexed market, address indexed proposer, uint256 stakeAmount, string evidenceUri);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool support, uint256 weight);
    event DisputeResolved(uint256 indexed disputeId, bool accepted);

    constructor(address admin, address aethToken_, address treasury_) {
        require(admin != address(0), "Invalid admin");
        require(aethToken_ != address(0), "Invalid token");
        require(treasury_ != address(0), "Invalid treasury");

        aethToken = IERC20(aethToken_);
        treasury = treasury_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(STAKING_ADMIN_ROLE, admin);
        _grantRole(REWARD_DISTRIBUTOR_ROLE, admin);
        _grantRole(MARKET_REGISTRAR_ROLE, admin);
        _grantRole(DISPUTE_ADMIN_ROLE, admin);
    }

    function setTreasury(address treasury_) external onlyRole(STAKING_ADMIN_ROLE) {
        require(treasury_ != address(0), "Invalid treasury");
        treasury = treasury_;
    }

    function registerMarket(address market) external onlyRole(MARKET_REGISTRAR_ROLE) {
        require(market != address(0), "Invalid market");
        _grantRole(MARKET_ROLE, market);
        emit MarketRegistered(market);
    }

    function stake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount is zero");
        _accrue(msg.sender);

        aethToken.safeTransferFrom(msg.sender, address(this), amount);

        stakes[msg.sender] += amount;
        totalStaked += amount;
        rewardDebt[msg.sender] = _rewardPerShareProduct(msg.sender);

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount is zero");
        require(stakes[msg.sender] >= amount, "Insufficient stake");

        _accrue(msg.sender);

        stakes[msg.sender] -= amount;
        totalStaked -= amount;
        rewardDebt[msg.sender] = _rewardPerShareProduct(msg.sender);

        aethToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    function fundRewards(uint256 amount) external onlyRole(REWARD_DISTRIBUTOR_ROLE) {
        require(amount > 0, "Amount is zero");
        require(totalStaked > 0, "No stakers");

        aethToken.safeTransferFrom(msg.sender, address(this), amount);
        accRewardsPerShareWad += (amount * 1e18) / totalStaked;

        emit RewardsFunded(amount);
    }

    function claimRewards() public nonReentrant {
        _accrue(msg.sender);
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "No rewards");

        pendingRewards[msg.sender] = 0;
        rewardDebt[msg.sender] = _rewardPerShareProduct(msg.sender);

        aethToken.safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    function claim_rewards() external {
        claimRewards();
    }

    function votingPower(address account) external view returns (uint256) {
        return stakes[account];
    }

    function submitDispute(address market, string calldata evidenceUri, uint256 stakeAmount) external nonReentrant returns (uint256 disputeId) {
        disputeId = _submitDispute(msg.sender, market, evidenceUri, stakeAmount);
    }

    function submitDisputeFromMarket(address disputer, address market, string calldata evidenceUri, uint256 stakeAmount)
        external
        nonReentrant
        onlyRole(MARKET_ROLE)
        returns (uint256 disputeId)
    {
        disputeId = _submitDispute(disputer, market, evidenceUri, stakeAmount);
    }

    function voteDispute(uint256 disputeId, bool support) public whenNotPaused {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.id != 0, "Dispute not found");
        require(!dispute.resolved, "Dispute resolved");
        require(!disputeVoted[disputeId][msg.sender], "Already voted");

        uint256 weight = stakes[msg.sender];
        require(weight > 0, "No stake");

        disputeVoted[disputeId][msg.sender] = true;
        if (support) {
            dispute.yesVotes += weight;
        } else {
            dispute.noVotes += weight;
        }

        emit DisputeVoted(disputeId, msg.sender, support, weight);
    }

    function vote(uint256 disputeId, bool support) external {
        voteDispute(disputeId, support);
    }

    function resolveDispute(uint256 disputeId, bool accepted) external nonReentrant onlyRole(DISPUTE_ADMIN_ROLE) {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.id != 0, "Dispute not found");
        require(!dispute.resolved, "Already resolved");

        dispute.resolved = true;
        dispute.accepted = accepted;

        if (accepted) {
            aethToken.safeTransfer(dispute.proposer, dispute.stakeAmount);
        } else {
            aethToken.safeTransfer(treasury, dispute.stakeAmount);
        }

        emit DisputeResolved(disputeId, accepted);
    }

    function pause() external onlyRole(STAKING_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(STAKING_ADMIN_ROLE) {
        _unpause();
    }

    function _submitDispute(address disputer, address market, string calldata evidenceUri, uint256 stakeAmount)
        internal
        returns (uint256 disputeId)
    {
        require(disputer != address(0), "Invalid disputer");
        require(market != address(0), "Invalid market");
        require(stakeAmount > 0, "Stake too low");

        aethToken.safeTransferFrom(disputer, address(this), stakeAmount);

        disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            market: market,
            proposer: disputer,
            evidenceUri: evidenceUri,
            stakeAmount: stakeAmount,
            createdAt: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            resolved: false,
            accepted: false
        });
        disputeHistory[disputer].push(disputeId);

        emit DisputeSubmitted(disputeId, market, disputer, stakeAmount, evidenceUri);
    }

    function _accrue(address account) internal {
        if (stakes[account] == 0) {
            rewardDebt[account] = 0;
            return;
        }

        uint256 accrued = _rewardPerShareProduct(account) - rewardDebt[account];
        if (accrued > 0) {
            pendingRewards[account] += accrued / 1e18;
        }
    }

    function _rewardPerShareProduct(address account) internal view returns (uint256) {
        return stakes[account] * accRewardsPerShareWad;
    }
}
