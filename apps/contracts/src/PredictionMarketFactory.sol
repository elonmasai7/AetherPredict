// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";

import {OutcomeTokenFactory} from "./OutcomeTokenFactory.sol";
import {PredictionMarket} from "./PredictionMarket.sol";

interface IGovernanceStakingRegistrar {
    function registerMarket(address market) external;
}

contract PredictionMarketFactory is AccessControl, Pausable {
    bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");

    struct MarketMeta {
        address market;
        address creator;
        address collateralToken;
        uint256 expiryDate;
        bool paused;
        bool resolved;
        string oracleSource;
        string title;
    }

    OutcomeTokenFactory public immutable outcomeTokenFactory;

    address public defaultCollateralToken;
    address public governanceStaking;
    address public liquidityVault;
    address public feeCollector;

    uint256 public creationFee;
    uint256 public defaultDisputeWindowSeconds = 1 days;
    uint256 public defaultMinDisputeStake = 100e18;
    uint256 public defaultProtocolFeeBps = 30;

    address[] public markets;
    mapping(address => MarketMeta) public marketMeta;

    event MarketCreated(address indexed market, string title, uint256 expiryDate);
    event MarketCreatedDetailed(
        address indexed market,
        address indexed creator,
        address indexed collateralToken,
        string oracleSource,
        uint256 expiryDate,
        string marketSymbol
    );
    event MarketPaused(address indexed market, bool paused);
    event MarketResolved(address indexed market, bool outcomeYes, uint256 confidenceScore);
    event CreationFeeUpdated(uint256 newFee);

    constructor(
        address admin,
        address outcomeTokenFactory_,
        address defaultCollateralToken_,
        uint256 creationFee_,
        address feeCollector_
    ) {
        require(admin != address(0), "Invalid admin");
        require(outcomeTokenFactory_ != address(0), "Invalid outcome factory");

        outcomeTokenFactory = OutcomeTokenFactory(outcomeTokenFactory_);
        defaultCollateralToken = defaultCollateralToken_;
        creationFee = creationFee_;
        feeCollector = feeCollector_ == address(0) ? admin : feeCollector_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MARKET_ADMIN_ROLE, admin);
    }

    function setCreationFee(uint256 newFee) external onlyRole(MARKET_ADMIN_ROLE) {
        creationFee = newFee;
        emit CreationFeeUpdated(newFee);
    }

    function setDefaultCollateralToken(address collateralToken) external onlyRole(MARKET_ADMIN_ROLE) {
        defaultCollateralToken = collateralToken;
    }

    function setGovernanceStaking(address governanceStaking_) external onlyRole(MARKET_ADMIN_ROLE) {
        governanceStaking = governanceStaking_;
    }

    function setLiquidityVault(address liquidityVault_) external onlyRole(MARKET_ADMIN_ROLE) {
        liquidityVault = liquidityVault_;
    }

    function setFeeCollector(address feeCollector_) external onlyRole(MARKET_ADMIN_ROLE) {
        require(feeCollector_ != address(0), "Invalid collector");
        feeCollector = feeCollector_;
    }

    function setDefaultDisputeWindow(uint256 disputeWindowSeconds_) external onlyRole(MARKET_ADMIN_ROLE) {
        defaultDisputeWindowSeconds = disputeWindowSeconds_;
    }

    function setDefaultMinDisputeStake(uint256 minDisputeStake_) external onlyRole(MARKET_ADMIN_ROLE) {
        defaultMinDisputeStake = minDisputeStake_;
    }

    function setDefaultProtocolFeeBps(uint256 protocolFeeBps_) external onlyRole(MARKET_ADMIN_ROLE) {
        require(protocolFeeBps_ <= 1_000, "Fee too high");
        defaultProtocolFeeBps = protocolFeeBps_;
    }

    function createMarket(
        string calldata title,
        string calldata description,
        string calldata oracleSource,
        uint256 expiryDate
    ) external payable whenNotPaused returns (address marketAddress) {
        marketAddress = _createMarket(title, description, oracleSource, expiryDate, defaultCollateralToken, _symbolFromTitle(title), defaultProtocolFeeBps);
    }

    function createMarket(
        string calldata title,
        string calldata description,
        string calldata oracleSource,
        uint256 expiryDate,
        address collateralToken,
        string calldata marketSymbol,
        uint256 protocolFeeBps
    ) external payable whenNotPaused returns (address marketAddress) {
        marketAddress = _createMarket(title, description, oracleSource, expiryDate, collateralToken, marketSymbol, protocolFeeBps);
    }

    function create_market(
        string calldata title,
        string calldata description,
        string calldata oracleSource,
        uint256 expiryDate
    ) external payable whenNotPaused returns (address marketAddress) {
        marketAddress = _createMarket(title, description, oracleSource, expiryDate, defaultCollateralToken, _symbolFromTitle(title), defaultProtocolFeeBps);
    }

    function pauseMarket(address market, bool pauseMarket_) public onlyRole(MARKET_ADMIN_ROLE) {
        require(marketMeta[market].market != address(0), "Market not found");
        if (pauseMarket_) {
            PredictionMarket(market).pause();
        } else {
            PredictionMarket(market).unpause();
        }
        marketMeta[market].paused = pauseMarket_;
        emit MarketPaused(market, pauseMarket_);
    }

    function pause_market(address market, bool pauseMarket_) external {
        pauseMarket(market, pauseMarket_);
    }

    function resolveMarket(address market, bool outcomeYes, uint256 confidenceScore, string calldata evidenceUri)
        external
        onlyRole(MARKET_ADMIN_ROLE)
    {
        require(marketMeta[market].market != address(0), "Market not found");

        if (outcomeYes) {
            PredictionMarket(market).settleYes(confidenceScore, evidenceUri);
        } else {
            PredictionMarket(market).settleNo(confidenceScore, evidenceUri);
        }

        marketMeta[market].resolved = PredictionMarket(market).resolved();
        emit MarketResolved(market, outcomeYes, confidenceScore);
    }

    function resolve_market(address market, bool outcomeYes, uint256 confidenceScore) external onlyRole(MARKET_ADMIN_ROLE) {
        require(marketMeta[market].market != address(0), "Market not found");
        PredictionMarket(market).resolve_market(outcomeYes, confidenceScore);
        marketMeta[market].resolved = true;
        emit MarketResolved(market, outcomeYes, confidenceScore);
    }

    function all_markets() external view returns (address[] memory) {
        return markets;
    }

    function _createMarket(
        string calldata title,
        string calldata description,
        string calldata oracleSource,
        uint256 expiryDate,
        address collateralToken,
        string memory marketSymbol,
        uint256 protocolFeeBps
    ) internal returns (address marketAddress) {
        require(msg.value >= creationFee, "Insufficient fee");
        require(expiryDate > block.timestamp, "Invalid expiry");

        PredictionMarket market = new PredictionMarket(
            msg.sender,
            address(this),
            collateralToken,
            title,
            description,
            oracleSource,
            expiryDate,
            defaultDisputeWindowSeconds,
            defaultMinDisputeStake,
            protocolFeeBps,
            feeCollector,
            governanceStaking,
            liquidityVault
        );

        (address yesToken, address noToken) = outcomeTokenFactory.createOutcomeTokens(address(market), marketSymbol);
        market.initializeOutcomeTokens(yesToken, noToken);

        if (governanceStaking != address(0)) {
            IGovernanceStakingRegistrar(governanceStaking).registerMarket(address(market));
        }

        marketAddress = address(market);
        markets.push(marketAddress);
        marketMeta[marketAddress] = MarketMeta({
            market: marketAddress,
            creator: msg.sender,
            collateralToken: collateralToken,
            expiryDate: expiryDate,
            paused: false,
            resolved: false,
            oracleSource: oracleSource,
            title: title
        });

        if (msg.value > 0) {
            (bool ok,) = payable(feeCollector).call{value: msg.value}("");
            require(ok, "Fee transfer failed");
        }

        emit MarketCreated(marketAddress, title, expiryDate);
        emit MarketCreatedDetailed(marketAddress, msg.sender, collateralToken, oracleSource, expiryDate, marketSymbol);
    }

    function _symbolFromTitle(string memory title) internal pure returns (string memory) {
        bytes memory value = bytes(title);
        uint256 maxLen = value.length > 12 ? 12 : value.length;
        bytes memory symbol = new bytes(maxLen);

        for (uint256 i = 0; i < maxLen; i++) {
            bytes1 char = value[i];
            if (char >= 0x61 && char <= 0x7A) {
                symbol[i] = bytes1(uint8(char) - 32);
            } else if (
                (char >= 0x41 && char <= 0x5A) ||
                (char >= 0x30 && char <= 0x39)
            ) {
                symbol[i] = char;
            } else {
                symbol[i] = "_";
            }
        }

        return string(symbol);
    }
}
