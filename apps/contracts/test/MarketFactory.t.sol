// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MarketFactory} from "../src/MarketFactory.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";

contract MarketFactoryTest is Test {
    MarketFactory internal factory;
    address internal trader = address(0xBEEF);

    function setUp() public {
        factory = new MarketFactory(address(this), 0.01 ether);
    }

    function testCreateMarket() public {
        address marketAddress = factory.create_market{value: 0.01 ether}(
            "Will BTC exceed $120k before Dec 31 2026?",
            "BTC market",
            "HashKey oracle",
            block.timestamp + 7 days
        );

        assertTrue(marketAddress != address(0));
        assertEq(factory.all_markets().length, 1);
    }

    function testPredictionMarketLifecycle() public {
        address marketAddress = factory.create_market{value: 0.01 ether}(
            "HashKey TVL market",
            "TVL market",
            "HashKey oracle",
            block.timestamp + 1 days
        );

        PredictionMarket market = PredictionMarket(payable(marketAddress));

        vm.deal(trader, 2 ether);
        vm.prank(trader);
        market.buy_yes{value: 1 ether}();

        vm.warp(block.timestamp + 2 days);
        market.resolve_market(true, 9100);

        vm.prank(trader);
        market.claim_rewards();
    }
}
