// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";

import {AETHToken} from "../src/AETHToken.sol";
import {GovernanceStaking} from "../src/GovernanceStaking.sol";
import {LiquidityVault} from "../src/LiquidityVault.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {OutcomeToken} from "../src/OutcomeToken.sol";
import {OutcomeTokenFactory} from "../src/OutcomeTokenFactory.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";
import {PredictionMarketFactory} from "../src/PredictionMarketFactory.sol";

contract MarketFactoryTest is Test {
    address internal traderYes = address(0xBEEF);
    address internal traderNo = address(0xCAFE);
    address internal lp = address(0xF00D);

    MockERC20 internal collateral;
    AETHToken internal aeth;
    OutcomeTokenFactory internal outcomeFactory;
    PredictionMarketFactory internal factory;
    GovernanceStaking internal staking;
    LiquidityVault internal liquidityVault;

    function setUp() public {
        collateral = new MockERC20("Mock USD", "mUSD", 18);
        aeth = new AETHToken(address(this), address(this), 100_000_000 ether);
        outcomeFactory = new OutcomeTokenFactory(address(this));

        factory = new PredictionMarketFactory(
            address(this),
            address(outcomeFactory),
            address(collateral),
            0,
            address(this)
        );
        factory.setDefaultMinDisputeStake(1 ether);

        outcomeFactory.grantRole(outcomeFactory.FACTORY_OPERATOR_ROLE(), address(factory));

        staking = new GovernanceStaking(address(this), address(aeth), address(this));
        liquidityVault = new LiquidityVault(address(this), address(collateral), address(aeth));

        collateral.mint(traderYes, 10_000 ether);
        collateral.mint(traderNo, 10_000 ether);
        collateral.mint(lp, 10_000 ether);

        aeth.transfer(traderYes, 2_000 ether);
        aeth.transfer(traderNo, 2_000 ether);
    }

    function testPredictionMarketLifecycleWithSettlement() public {
        address marketAddress = factory.create_market(
            "BTC_120K",
            "Will BTC exceed 120k?",
            "HashKey Oracle",
            block.timestamp + 1 days
        );

        PredictionMarket market = PredictionMarket(marketAddress);
        OutcomeToken yesToken = OutcomeToken(address(market.yesToken()));

        vm.startPrank(traderYes);
        collateral.approve(marketAddress, 1_000 ether);
        market.buyYes(1_000 ether);
        assertEq(yesToken.balanceOf(traderYes), 997 ether);

        market.sellPosition(true, 200 ether);
        assertEq(yesToken.balanceOf(traderYes), 797 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        market.resolve_market(true, 9500);

        uint256 balanceBefore = collateral.balanceOf(traderYes);
        vm.prank(traderYes);
        market.claimWinnings();
        uint256 balanceAfter = collateral.balanceOf(traderYes);

        assertEq(balanceAfter - balanceBefore, 797 ether);
        assertEq(yesToken.balanceOf(traderYes), 0);
    }

    function testDisputeFlowAndFinalizationHook() public {
        address marketAddress = factory.create_market(
            "ETH_10K",
            "Will ETH exceed 10k?",
            "HashKey Oracle",
            block.timestamp + 1 days
        );

        PredictionMarket market = PredictionMarket(marketAddress);
        OutcomeToken noToken = OutcomeToken(address(market.noToken()));

        vm.startPrank(traderNo);
        collateral.approve(marketAddress, 1_200 ether);
        market.buyNo(1_200 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        market.settleYes(8100, "ipfs://initial");
        vm.deal(traderNo, 2 ether);

        vm.startPrank(traderNo);
        collateral.approve(marketAddress, 20 ether);
        market.disputeOutcome{value: 1 ether}("ipfs://counter-evidence", 20 ether);
        vm.stopPrank();

        vm.expectRevert("Already proposed");
        market.settleYes(8200, "ipfs://another");

        market.finalizeDispute(false, 9000, "governance-overturn");

        uint256 beforeClaim = collateral.balanceOf(traderNo);
        vm.prank(traderNo);
        market.claimWinnings();
        uint256 afterClaim = collateral.balanceOf(traderNo);

        assertEq(noToken.balanceOf(traderNo), 0);
        assertEq(afterClaim - beforeClaim, (1_200 ether * (10_000 - 30)) / 10_000);
    }

    function testLiquidityAndStakingRewardsSurface() public {
        vm.startPrank(lp);
        collateral.approve(address(liquidityVault), 2_000 ether);
        liquidityVault.deposit(2_000 ether);
        vm.stopPrank();

        collateral.mint(address(this), 500 ether);
        collateral.approve(address(liquidityVault), 500 ether);
        liquidityVault.distributeFees(500 ether);

        aeth.approve(address(liquidityVault), 1_000 ether);
        liquidityVault.distributeAethRewards(1_000 ether);

        uint256 feeBefore = collateral.balanceOf(lp);
        uint256 rewardBefore = aeth.balanceOf(lp);

        vm.prank(lp);
        liquidityVault.claimRewards();

        uint256 feeAfter = collateral.balanceOf(lp);
        uint256 rewardAfter = aeth.balanceOf(lp);

        assertGt(feeAfter, feeBefore);
        assertGt(rewardAfter, rewardBefore);

        vm.startPrank(traderYes);
        aeth.approve(address(staking), 500 ether);
        staking.stake(500 ether);
        vm.stopPrank();

        vm.startPrank(traderNo);
        aeth.approve(address(staking), 300 ether);
        staking.stake(300 ether);
        vm.stopPrank();

        vm.startPrank(traderYes);
        aeth.approve(address(staking), 100 ether);
        uint256 disputeId = staking.submitDispute(address(0xABCD), "ipfs://dispute", 100 ether);
        vm.stopPrank();

        vm.prank(traderNo);
        staking.voteDispute(disputeId, true);

        aeth.approve(address(staking), 200 ether);
        staking.fundRewards(200 ether);

        uint256 stakingRewardBefore = aeth.balanceOf(traderNo);
        vm.prank(traderNo);
        staking.claimRewards();
        uint256 stakingRewardAfter = aeth.balanceOf(traderNo);

        assertGt(stakingRewardAfter - stakingRewardBefore, 0);
    }
}
