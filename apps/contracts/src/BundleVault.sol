// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";

contract BundleVault is AccessControl, Pausable {
    bytes32 public constant BUNDLE_MANAGER_ROLE = keccak256("BUNDLE_MANAGER_ROLE");

    struct Bundle {
        string name;
        string theme;
        address[] markets;
        uint256 totalDeposits;
        bool active;
    }

    uint256 public nextBundleId = 1;
    mapping(uint256 => Bundle) public bundles;
    mapping(uint256 => mapping(address => uint256)) public bundleBalances;

    event BundleCreated(uint256 indexed bundleId, string name, string theme);
    event BundleInvested(uint256 indexed bundleId, address indexed investor, uint256 amount);
    event BundleWithdrawn(uint256 indexed bundleId, address indexed investor, uint256 amount);
    event BundleRebalanced(uint256 indexed bundleId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BUNDLE_MANAGER_ROLE, admin);
    }

    function create_bundle(string calldata name, string calldata theme, address[] calldata markets) external onlyRole(BUNDLE_MANAGER_ROLE) returns (uint256 bundleId) {
        bundleId = nextBundleId++;
        bundles[bundleId] = Bundle({
            name: name,
            theme: theme,
            markets: markets,
            totalDeposits: 0,
            active: true
        });
        emit BundleCreated(bundleId, name, theme);
    }

    function invest_bundle(uint256 bundleId) external payable whenNotPaused {
        Bundle storage bundle = bundles[bundleId];
        require(bundle.active, "Bundle inactive");
        require(msg.value > 0, "No amount");
        bundle.totalDeposits += msg.value;
        bundleBalances[bundleId][msg.sender] += msg.value;
        emit BundleInvested(bundleId, msg.sender, msg.value);
    }

    function withdraw_bundle(uint256 bundleId, uint256 amount) external whenNotPaused {
        require(bundleBalances[bundleId][msg.sender] >= amount, "Insufficient balance");
        bundleBalances[bundleId][msg.sender] -= amount;
        bundles[bundleId].totalDeposits -= amount;
        payable(msg.sender).transfer(amount);
        emit BundleWithdrawn(bundleId, msg.sender, amount);
    }

    function rebalance_bundle(uint256 bundleId) external onlyRole(BUNDLE_MANAGER_ROLE) {
        require(bundles[bundleId].active, "Bundle inactive");
        emit BundleRebalanced(bundleId);
    }
}
