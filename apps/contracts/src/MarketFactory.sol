// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {PredictionMarket} from "./PredictionMarket.sol";

contract MarketFactory is AccessControl, Pausable {
    bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");

    address[] public markets;
    uint256 public creationFee;

    event MarketCreated(address indexed market, string title, uint256 expiryDate);
    event CreationFeeUpdated(uint256 newFee);

    constructor(address admin, uint256 creationFee_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MARKET_ADMIN_ROLE, admin);
        creationFee = creationFee_;
    }

    function create_market(
        string calldata title,
        string calldata description,
        string calldata oracleSource,
        uint256 expiryDate
    ) external payable whenNotPaused returns (address marketAddress) {
        require(msg.value >= creationFee, "Insufficient fee");
        PredictionMarket market = new PredictionMarket(msg.sender, title, description, oracleSource, expiryDate);
        markets.push(address(market));
        emit MarketCreated(address(market), title, expiryDate);
        return address(market);
    }

    function all_markets() external view returns (address[] memory) {
        return markets;
    }

    function set_creation_fee(uint256 newFee) external onlyRole(MARKET_ADMIN_ROLE) {
        creationFee = newFee;
        emit CreationFeeUpdated(newFee);
    }
}
