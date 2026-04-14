// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {OutcomeToken} from "./OutcomeToken.sol";

contract OutcomeTokenFactory is AccessControl {
    bytes32 public constant FACTORY_ADMIN_ROLE = keccak256("FACTORY_ADMIN_ROLE");
    bytes32 public constant MARKET_FACTORY_ROLE = keccak256("MARKET_FACTORY_ROLE");
    bytes32 public constant FACTORY_OPERATOR_ROLE = MARKET_FACTORY_ROLE;

    struct OutcomePair {
        address yesToken;
        address noToken;
    }

    mapping(address => OutcomePair) public marketOutcomeTokens;

    event OutcomeTokensCreated(address indexed market, address yesToken, address noToken, string marketSymbol);
    event OutcomeTokenPairCreated(address indexed market, address yesToken, address noToken);

    constructor(address admin) {
        require(admin != address(0), "Invalid admin");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FACTORY_ADMIN_ROLE, admin);
        _grantRole(MARKET_FACTORY_ROLE, admin);
    }

    function createOutcomeTokens(address market, string calldata marketSymbol)
        external
        onlyRole(MARKET_FACTORY_ROLE)
        returns (address yesToken, address noToken)
    {
        return _createOutcomePair(
            market,
            string.concat("Aether YES ", marketSymbol),
            string.concat("pYES-", marketSymbol),
            string.concat("Aether NO ", marketSymbol),
            string.concat("pNO-", marketSymbol),
            marketSymbol
        );
    }

    function createOutcomeTokenPair(
        address market,
        string calldata yesName,
        string calldata yesSymbol,
        string calldata noName,
        string calldata noSymbol
    ) external onlyRole(MARKET_FACTORY_ROLE) returns (address yesToken, address noToken) {
        return _createOutcomePair(market, yesName, yesSymbol, noName, noSymbol, "");
    }

    function _createOutcomePair(
        address market,
        string memory yesName,
        string memory yesSymbol,
        string memory noName,
        string memory noSymbol,
        string memory marketSymbol
    ) internal returns (address yesToken, address noToken) {
        require(market != address(0), "Invalid market");
        require(marketOutcomeTokens[market].yesToken == address(0), "Already created");

        OutcomeToken yes = new OutcomeToken(yesName, yesSymbol, address(this), market);
        OutcomeToken no = new OutcomeToken(noName, noSymbol, address(this), market);

        marketOutcomeTokens[market] = OutcomePair({yesToken: address(yes), noToken: address(no)});

        emit OutcomeTokenPairCreated(market, address(yes), address(no));
        emit OutcomeTokensCreated(market, address(yes), address(no), marketSymbol);

        return (address(yes), address(no));
    }
}
