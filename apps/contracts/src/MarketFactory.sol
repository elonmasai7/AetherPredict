// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {OutcomeTokenFactory} from "./OutcomeTokenFactory.sol";
import {PredictionMarketFactory} from "./PredictionMarketFactory.sol";

contract MarketFactory is PredictionMarketFactory {
    constructor(address admin, uint256 creationFee_)
        PredictionMarketFactory(
            admin,
            address(new OutcomeTokenFactory(admin)),
            address(0),
            creationFee_,
            admin
        )
    {}
}
