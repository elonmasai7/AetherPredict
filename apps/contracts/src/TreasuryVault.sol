// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract TreasuryVault is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    uint256 public protocolRevenue;
    uint256 public insuranceReserve;
    uint256 public lpRewardsPool;

    event FeesDeposited(uint256 amount, uint256 protocolShare, uint256 insuranceShare, uint256 lpShare);
    event TreasuryWithdrawn(address indexed to, uint256 amount);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(TREASURER_ROLE, admin);
    }

    receive() external payable {
        depositFees();
    }

    function depositFees() public payable whenNotPaused {
        uint256 protocolShare = (msg.value * 50) / 100;
        uint256 insuranceShare = (msg.value * 20) / 100;
        uint256 lpShare = msg.value - protocolShare - insuranceShare;

        protocolRevenue += protocolShare;
        insuranceReserve += insuranceShare;
        lpRewardsPool += lpShare;

        emit FeesDeposited(msg.value, protocolShare, insuranceShare, lpShare);
    }

    function withdraw(address payable to, uint256 amount) external onlyRole(TREASURER_ROLE) nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
        emit TreasuryWithdrawn(to, amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
