// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityVault is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    struct MarketDepth {
        uint256 yesPool;
        uint256 noPool;
        uint256 spreadBps;
        uint256 updatedAt;
    }

    IERC20 public immutable collateralToken;
    IERC20 public immutable aethToken;

    uint256 public totalShares;
    uint256 public totalCollateral;
    uint256 public accFeePerShareWad;
    uint256 public accAethPerShareWad;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public feeDebt;
    mapping(address => uint256) public aethDebt;
    mapping(address => uint256) public pendingFee;
    mapping(address => uint256) public pendingAeth;

    mapping(address => MarketDepth) public marketDepth;

    event Deposited(address indexed provider, uint256 collateralAmount, uint256 sharesMinted);
    event Withdrawn(address indexed provider, uint256 collateralAmount, uint256 sharesBurned);
    event FeesDistributed(uint256 amount);
    event AethRewardsDistributed(uint256 amount);
    event RewardsClaimed(address indexed provider, uint256 feeAmount, uint256 aethAmount);
    event MarketDepthUpdated(address indexed market, uint256 yesPool, uint256 noPool, uint256 spreadBps);

    constructor(address admin, address collateralToken_, address aethToken_) {
        require(admin != address(0), "Invalid admin");
        require(collateralToken_ != address(0), "Invalid collateral token");
        require(aethToken_ != address(0), "Invalid AETH token");

        collateralToken = IERC20(collateralToken_);
        aethToken = IERC20(aethToken_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_ADMIN_ROLE, admin);
        _grantRole(DISTRIBUTOR_ROLE, admin);
    }

    function deposit(uint256 collateralAmount) external whenNotPaused nonReentrant returns (uint256 mintedShares) {
        require(collateralAmount > 0, "Amount is zero");

        _accrue(msg.sender);
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);

        if (totalShares == 0 || totalCollateral == 0) {
            mintedShares = collateralAmount;
        } else {
            mintedShares = (collateralAmount * totalShares) / totalCollateral;
        }

        totalShares += mintedShares;
        totalCollateral += collateralAmount;
        shares[msg.sender] += mintedShares;

        feeDebt[msg.sender] = _feeProduct(msg.sender);
        aethDebt[msg.sender] = _aethProduct(msg.sender);

        emit Deposited(msg.sender, collateralAmount, mintedShares);
    }

    function withdraw(uint256 shareAmount) external whenNotPaused nonReentrant returns (uint256 collateralAmount) {
        require(shareAmount > 0, "Amount is zero");
        require(shares[msg.sender] >= shareAmount, "Insufficient shares");

        _accrue(msg.sender);

        collateralAmount = (shareAmount * totalCollateral) / totalShares;
        shares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;
        totalCollateral -= collateralAmount;

        feeDebt[msg.sender] = _feeProduct(msg.sender);
        aethDebt[msg.sender] = _aethProduct(msg.sender);

        collateralToken.safeTransfer(msg.sender, collateralAmount);

        emit Withdrawn(msg.sender, collateralAmount, shareAmount);
    }

    function distributeFees(uint256 amount) external onlyRole(DISTRIBUTOR_ROLE) {
        require(amount > 0, "Amount is zero");
        require(totalShares > 0, "No LPs");

        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        totalCollateral += amount;
        accFeePerShareWad += (amount * 1e18) / totalShares;

        emit FeesDistributed(amount);
    }

    function distributeAethRewards(uint256 amount) external onlyRole(DISTRIBUTOR_ROLE) {
        require(amount > 0, "Amount is zero");
        require(totalShares > 0, "No LPs");

        aethToken.safeTransferFrom(msg.sender, address(this), amount);
        accAethPerShareWad += (amount * 1e18) / totalShares;

        emit AethRewardsDistributed(amount);
    }

    function claimRewards() external nonReentrant {
        _accrue(msg.sender);

        uint256 feeAmount = pendingFee[msg.sender];
        uint256 aethAmount = pendingAeth[msg.sender];
        require(feeAmount > 0 || aethAmount > 0, "No rewards");

        if (feeAmount > 0) {
            pendingFee[msg.sender] = 0;
            collateralToken.safeTransfer(msg.sender, feeAmount);
        }

        if (aethAmount > 0) {
            pendingAeth[msg.sender] = 0;
            aethToken.safeTransfer(msg.sender, aethAmount);
        }

        feeDebt[msg.sender] = _feeProduct(msg.sender);
        aethDebt[msg.sender] = _aethProduct(msg.sender);

        emit RewardsClaimed(msg.sender, feeAmount, aethAmount);
    }

    function updateMarketDepth(address market, uint256 yesPool, uint256 noPool, uint256 spreadBps) external onlyRole(DISTRIBUTOR_ROLE) {
        require(market != address(0), "Invalid market");

        marketDepth[market] = MarketDepth({
            yesPool: yesPool,
            noPool: noPool,
            spreadBps: spreadBps,
            updatedAt: block.timestamp
        });

        emit MarketDepthUpdated(market, yesPool, noPool, spreadBps);
    }

    function pause() external onlyRole(VAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(VAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _accrue(address account) internal {
        uint256 feeAccrued = _feeProduct(account) - feeDebt[account];
        if (feeAccrued > 0) {
            pendingFee[account] += feeAccrued / 1e18;
        }

        uint256 aethAccrued = _aethProduct(account) - aethDebt[account];
        if (aethAccrued > 0) {
            pendingAeth[account] += aethAccrued / 1e18;
        }
    }

    function _feeProduct(address account) internal view returns (uint256) {
        return shares[account] * accFeePerShareWad;
    }

    function _aethProduct(address account) internal view returns (uint256) {
        return shares[account] * accAethPerShareWad;
    }
}
