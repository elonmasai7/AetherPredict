// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";

import {AETHToken} from "../src/AETHToken.sol";
import {GovernanceStaking} from "../src/GovernanceStaking.sol";
import {LiquidityVault} from "../src/LiquidityVault.sol";
import {OutcomeToken} from "../src/OutcomeToken.sol";
import {OutcomeTokenFactory} from "../src/OutcomeTokenFactory.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";
import {PredictionMarketFactory} from "../src/PredictionMarketFactory.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract MarketFactoryTest is Test {
    AETHToken internal aeth;
    GovernanceStaking internal governanceStaking;
    LiquidityVault internal liquidityVault;
    OutcomeTokenFactory internal outcomeFactory;
    PredictionMarketFactory internal factory;
    MockERC20 internal usdc;

    address internal trader = address(0xBEEF);
    address internal lp = address(0xCAFE);
    address internal disputer = address(0xD15E);
    address internal feeCollector = address(0xFEE1);

    function setUp() public {
        usdc = new MockERC20("USD Coin", "USDC", 18);
        aeth = new AETHToken(address(this), address(this), 100_000_000 ether);
        outcomeFactory = new OutcomeTokenFactory(address(this));
        governanceStaking = new GovernanceStaking(address(this), address(aeth), address(this));
        liquidityVault = new LiquidityVault(address(this), address(usdc), address(aeth));

        factory = new PredictionMarketFactory(
            address(this),
            address(outcomeFactory),
            address(usdc),
            0.01 ether,
            feeCollector
        );

        factory.setDefaultProtocolFeeBps(0);
        factory.setDefaultDisputeWindow(1 hours);
        factory.setDefaultMinDisputeStake(10 ether);
        factory.setGovernanceStaking(address(governanceStaking));
        factory.setLiquidityVault(address(liquidityVault));

        outcomeFactory.grantRole(outcomeFactory.MARKET_FACTORY_ROLE(), address(factory));
        governanceStaking.grantRole(governanceStaking.MARKET_REGISTRAR_ROLE(), address(factory));

        usdc.mint(trader, 1_000_000 ether);
        usdc.mint(lp, 1_000_000 ether);
        aeth.transfer(disputer, 10_000 ether);
        aeth.transfer(lp, 10_000 ether);
    }

    function testMarketLifecycleErc20Collateral() public {
        address marketAddress = factory.createMarket{value: 0.01 ether}(
            "BTC > 120k",
            "Market description",
            "hashkey:oracle:btc",
            block.timestamp + 1 days
        );

        PredictionMarket market = PredictionMarket(payable(marketAddress));
        OutcomeToken yesToken = market.yesToken();

        vm.startPrank(trader);
        usdc.approve(marketAddress, type(uint256).max);
        market.buyYes(100 ether);

        assertEq(yesToken.balanceOf(trader), 100 ether);
        assertEq(market.yesPool(), 100 ether);

        market.sellPosition(true, 40 ether);
        assertEq(yesToken.balanceOf(trader), 60 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        market.settleYes(9200, "ipfs://resolution/1");
        vm.warp(block.timestamp + 2 hours);
        market.finalizeSettlement();

        uint256 beforeBalance = usdc.balanceOf(trader);
        vm.prank(trader);
        market.claimWinnings();

        assertEq(usdc.balanceOf(trader), beforeBalance + 60 ether);
        assertEq(yesToken.balanceOf(trader), 0);
    }

    function testDisputeStakeFlowAndFinalizeDispute() public {
        address marketAddress = factory.createMarket{value: 0.01 ether}(
            "ETH > 10k",
            "Market description",
            "hashkey:oracle:eth",
            block.timestamp + 1 days
        );

        PredictionMarket market = PredictionMarket(payable(marketAddress));
        OutcomeToken noToken = market.noToken();

        vm.startPrank(trader);
        usdc.approve(marketAddress, type(uint256).max);
        market.buyNo(50 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        market.settleYes(8500, "ipfs://resolution/proposed");

        vm.startPrank(disputer);
        aeth.approve(address(governanceStaking), type(uint256).max);
        market.disputeOutcome("ipfs://evidence/dispute-1", 10 ether);
        vm.stopPrank();

        assertTrue(market.disputed());

        vm.startPrank(lp);
        aeth.approve(address(governanceStaking), type(uint256).max);
        governanceStaking.stake(500 ether);
        governanceStaking.voteDispute(1, true);
        vm.stopPrank();

        governanceStaking.resolveDispute(1, true);
        market.finalizeDispute(false, 8800, "appeal-accepted");

        uint256 beforeBalance = usdc.balanceOf(trader);
        vm.prank(trader);
        market.claimWinnings();

        assertEq(usdc.balanceOf(trader), beforeBalance + 50 ether);
        assertEq(noToken.balanceOf(trader), 0);
    }

    function testLiquidityAndStakingRewardsSurface() public {
        vm.startPrank(lp);
        usdc.approve(address(liquidityVault), type(uint256).max);
        liquidityVault.deposit(200 ether);
        vm.stopPrank();

        usdc.mint(address(this), 30 ether);
        usdc.approve(address(liquidityVault), type(uint256).max);
        liquidityVault.distributeFees(30 ether);

        aeth.approve(address(liquidityVault), type(uint256).max);
        liquidityVault.distributeAethRewards(20 ether);

        uint256 lpBeforeUsdc = usdc.balanceOf(lp);
        uint256 lpBeforeAeth = aeth.balanceOf(lp);

        vm.prank(lp);
        liquidityVault.claimRewards();

        assertGt(usdc.balanceOf(lp), lpBeforeUsdc);
        assertGt(aeth.balanceOf(lp), lpBeforeAeth);

        vm.startPrank(lp);
        aeth.approve(address(governanceStaking), type(uint256).max);
        governanceStaking.stake(200 ether);
        vm.stopPrank();

        aeth.approve(address(governanceStaking), type(uint256).max);
        governanceStaking.fundRewards(100 ether);

        uint256 stakingBefore = aeth.balanceOf(lp);
        vm.prank(lp);
        governanceStaking.claimRewards();

        assertGt(aeth.balanceOf(lp), stakingBefore);
    }

    function testLegacyAliasesRemainOperationalForNativeMarkets() public {
        address marketAddress = factory.createMarket{value: 0.01 ether}(
            "Native Alias Market",
            "Legacy path",
            "hashkey:oracle:native",
            block.timestamp + 1 days,
            address(0),
            "NATIVE_ALIAS",
            0
        );

        PredictionMarket market = PredictionMarket(payable(marketAddress));

        vm.deal(trader, 5 ether);
        vm.prank(trader);
        market.buy_yes{value: 1 ether}();

        vm.warp(block.timestamp + 2 days);
        market.resolve_market(true, 9000);

        uint256 nativeBefore = trader.balance;
        vm.prank(trader);
        market.claim_rewards();

        assertEq(trader.balance, nativeBefore + 1 ether);
    }
}
