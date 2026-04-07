// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {VaultShareToken} from "./VaultShareToken.sol";

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract StrategyVault is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct VaultPerformance {
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        uint256 totalReturnsDistributed;
        uint256 navPerShareWad;
        uint256 aum;
        uint256 lastUpdated;
    }

    string public vaultTitle;
    string public strategyDescription;
    string public riskProfile;
    string public managerType;

    address public collateralToken;
    VaultShareToken public shareToken;

    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public totalReturnsDistributed;
    uint256 public navPerShareWad;
    uint256 public aum;
    uint256 public lastUpdated;

    event Deposit(address indexed account, uint256 amount, uint256 sharesMinted);
    event Withdraw(address indexed account, uint256 amount, uint256 sharesBurned);
    event TradeExecuted(address indexed market, bytes32 action, uint256 amount);
    event VaultRebalanced(uint256 timestamp);
    event ReturnsDistributed(uint256 grossReturn);

    constructor(
        address manager,
        address collateralToken_,
        string memory title_,
        string memory description_,
        string memory riskProfile_,
        string memory managerType_,
        uint256 managementFeeBps,
        uint256 performanceFeeBps,
        string memory shareName,
        string memory shareSymbol
    ) {
        vaultTitle = title_;
        strategyDescription = description_;
        riskProfile = riskProfile_;
        managerType = managerType_;
        collateralToken = collateralToken_;
        navPerShareWad = 1e18;
        lastUpdated = block.timestamp;

        managementFeeBps;
        performanceFeeBps;

        _grantRole(DEFAULT_ADMIN_ROLE, manager);
        _grantRole(MANAGER_ROLE, manager);

        shareToken = new VaultShareToken(shareName, shareSymbol, address(this));
        shareToken.setNavPerShare(navPerShareWad);
    }

    function deposit(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "No deposit");
        require(IERC20Minimal(collateralToken).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 sharesToMint = (amount * 1e18) / navPerShareWad;
        totalDeposits += amount;
        aum += amount;
        shareToken.mint(msg.sender, sharesToMint);
        _updateNav();
        emit Deposit(msg.sender, amount, sharesToMint);
    }

    function withdraw(uint256 shareAmount) external whenNotPaused nonReentrant {
        require(shareAmount > 0, "No shares");
        uint256 amount = (shareAmount * navPerShareWad) / 1e18;
        require(amount <= aum, "Insufficient liquidity");
        shareToken.burn(msg.sender, shareAmount);
        totalWithdrawals += amount;
        aum -= amount;
        _updateNav();
        require(IERC20Minimal(collateralToken).transfer(msg.sender, amount), "Transfer failed");
        emit Withdraw(msg.sender, amount, shareAmount);
    }

    function executeTrade(address market, bytes32 action, uint256 amount) external onlyRole(MANAGER_ROLE) {
        require(market != address(0), "Invalid market");
        require(amount <= aum, "Amount exceeds assets");
        emit TradeExecuted(market, action, amount);
    }

    function rebalance() external onlyRole(MANAGER_ROLE) {
        emit VaultRebalanced(block.timestamp);
    }

    function distributeReturns(uint256 grossReturn) external onlyRole(MANAGER_ROLE) {
        totalReturnsDistributed += grossReturn;
        aum += grossReturn;
        _updateNav();
        emit ReturnsDistributed(grossReturn);
    }

    function getVaultPerformance() external view returns (VaultPerformance memory) {
        return VaultPerformance({
            totalDeposits: totalDeposits,
            totalWithdrawals: totalWithdrawals,
            totalReturnsDistributed: totalReturnsDistributed,
            navPerShareWad: navPerShareWad,
            aum: aum,
            lastUpdated: lastUpdated
        });
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function _updateNav() internal {
        uint256 supply = shareToken.totalSupply();
        navPerShareWad = supply == 0 ? 1e18 : (aum * 1e18) / supply;
        shareToken.setNavPerShare(navPerShareWad);
        lastUpdated = block.timestamp;
    }
}
