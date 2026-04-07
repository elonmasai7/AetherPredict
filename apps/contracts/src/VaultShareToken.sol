// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract VaultShareToken is ERC20, AccessControl {
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    uint256 public navPerShareWad;

    constructor(string memory name_, string memory symbol_, address vault) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, vault);
        _grantRole(VAULT_ROLE, vault);
        navPerShareWad = 1e18;
    }

    function mint(address to, uint256 amount) external onlyRole(VAULT_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(VAULT_ROLE) {
        _burn(from, amount);
    }

    function setNavPerShare(uint256 navWad) external onlyRole(VAULT_ROLE) {
        navPerShareWad = navWad;
    }

    function calculateNav(uint256 totalVaultValue, uint256 totalShares) external pure returns (uint256) {
        if (totalShares == 0) {
            return 1e18;
        }
        return (totalVaultValue * 1e18) / totalShares;
    }
}
