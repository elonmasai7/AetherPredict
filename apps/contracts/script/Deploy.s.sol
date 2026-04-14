// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";

import {AETHToken} from "../src/AETHToken.sol";
import {OutcomeTokenFactory} from "../src/OutcomeTokenFactory.sol";
import {PredictionMarketFactory} from "../src/PredictionMarketFactory.sol";
import {LiquidityVault} from "../src/LiquidityVault.sol";
import {GovernanceStaking} from "../src/GovernanceStaking.sol";

import {TreasuryVault} from "../src/TreasuryVault.sol";
import {BundleVault} from "../src/BundleVault.sol";
import {InsurancePool} from "../src/InsurancePool.sol";
import {StrategyVaultFactory} from "../src/StrategyVaultFactory.sol";

contract DeployAetherPredict is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("HASHKEY_PRIVATE_KEY");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        address defaultCollateral = vm.envOr("HASHKEY_USDC_ADDRESS", address(0));

        vm.startBroadcast(deployerPrivateKey);

        AETHToken aeth = new AETHToken(msg.sender, treasuryAddress, 100_000_000 ether);
        OutcomeTokenFactory outcomeFactory = new OutcomeTokenFactory(msg.sender);
        GovernanceStaking governanceStaking = new GovernanceStaking(msg.sender, address(aeth), treasuryAddress);
        LiquidityVault liquidityVault = new LiquidityVault(msg.sender, defaultCollateral, address(aeth));

        PredictionMarketFactory predictionFactory = new PredictionMarketFactory(
            msg.sender,
            address(outcomeFactory),
            defaultCollateral,
            0.01 ether,
            treasuryAddress
        );

        predictionFactory.setGovernanceStaking(address(governanceStaking));
        predictionFactory.setLiquidityVault(address(liquidityVault));

        outcomeFactory.grantRole(outcomeFactory.MARKET_FACTORY_ROLE(), address(predictionFactory));
        governanceStaking.grantRole(governanceStaking.MARKET_REGISTRAR_ROLE(), address(predictionFactory));
        liquidityVault.grantRole(liquidityVault.DISTRIBUTOR_ROLE(), address(predictionFactory));

        aeth.grantRole(aeth.REWARD_DISTRIBUTOR_ROLE(), address(governanceStaking));
        aeth.grantRole(aeth.REWARD_DISTRIBUTOR_ROLE(), address(liquidityVault));

        TreasuryVault treasury = new TreasuryVault(msg.sender);
        BundleVault bundleVault = new BundleVault(msg.sender);
        InsurancePool insurancePool = new InsurancePool(msg.sender);
        StrategyVaultFactory vaultFactory = new StrategyVaultFactory(msg.sender);

        aeth;
        outcomeFactory;
        governanceStaking;
        liquidityVault;
        predictionFactory;
        treasury;
        bundleVault;
        insurancePool;
        vaultFactory;

        vm.stopBroadcast();
    }
}
