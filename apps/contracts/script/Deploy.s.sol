// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {TreasuryVault} from "../src/TreasuryVault.sol";
import {ReputationStaking} from "../src/ReputationStaking.sol";
import {BundleVault} from "../src/BundleVault.sol";
import {InsurancePool} from "../src/InsurancePool.sol";
import {StrategyVaultFactory} from "../src/StrategyVaultFactory.sol";

contract DeployAetherPredict is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("HASHKEY_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TreasuryVault treasury = new TreasuryVault(msg.sender);
        ReputationStaking reputation = new ReputationStaking(msg.sender);
        MarketFactory factory = new MarketFactory(msg.sender, 0.01 ether);
        BundleVault bundleVault = new BundleVault(msg.sender);
        InsurancePool insurancePool = new InsurancePool(msg.sender);
        StrategyVaultFactory vaultFactory = new StrategyVaultFactory(msg.sender);

        treasury;
        reputation;
        factory;
        bundleVault;
        insurancePool;
        vaultFactory;

        vm.stopBroadcast();
    }
}
