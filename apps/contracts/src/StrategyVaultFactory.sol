// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

import {StrategyVault} from "./StrategyVault.sol";

contract StrategyVaultFactory is AccessControl {
    bytes32 public constant VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");

    struct VaultMeta {
        address vault;
        address collateralToken;
        bool paused;
        bool archived;
    }

    uint256 public nextVaultId = 1;
    mapping(uint256 => VaultMeta) public vaults;

    event VaultCreated(uint256 indexed vaultId, address indexed vault, string title, string riskProfile, string managerType);
    event VaultPaused(uint256 indexed vaultId, bool paused);
    event VaultArchived(uint256 indexed vaultId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VAULT_ADMIN_ROLE, admin);
    }

    function createVault(
        address manager,
        address collateralToken,
        string calldata title,
        string calldata strategyDescription,
        string calldata riskProfile,
        string calldata managerType,
        uint256 managementFeeBps,
        uint256 performanceFeeBps,
        string calldata shareName,
        string calldata shareSymbol
    ) external onlyRole(VAULT_ADMIN_ROLE) returns (uint256 vaultId, address vaultAddress) {
        StrategyVault vault = new StrategyVault(
            manager,
            collateralToken,
            title,
            strategyDescription,
            riskProfile,
            managerType,
            managementFeeBps,
            performanceFeeBps,
            shareName,
            shareSymbol
        );
        vaultId = nextVaultId++;
        vaultAddress = address(vault);
        vaults[vaultId] = VaultMeta({vault: vaultAddress, collateralToken: collateralToken, paused: false, archived: false});
        emit VaultCreated(vaultId, vaultAddress, title, riskProfile, managerType);
    }

    function pauseVault(uint256 vaultId, bool paused) external onlyRole(VAULT_ADMIN_ROLE) {
        VaultMeta storage meta = vaults[vaultId];
        require(meta.vault != address(0), "Vault not found");
        if (paused) {
            StrategyVault(meta.vault).pause();
        } else {
            StrategyVault(meta.vault).unpause();
        }
        meta.paused = paused;
        emit VaultPaused(vaultId, paused);
    }

    function archiveVault(uint256 vaultId) external onlyRole(VAULT_ADMIN_ROLE) {
        VaultMeta storage meta = vaults[vaultId];
        require(meta.vault != address(0), "Vault not found");
        meta.archived = true;
        emit VaultArchived(vaultId);
    }
}
