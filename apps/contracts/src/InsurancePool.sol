// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract InsurancePool is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant CLAIMS_ROLE = keccak256("CLAIMS_ROLE");

    struct Cover {
        address buyer;
        uint256 premium;
        uint256 coverageAmount;
        bool active;
        bool claimed;
    }

    uint256 public nextCoverId = 1;
    mapping(uint256 => Cover) public covers;

    event CoverPurchased(uint256 indexed coverId, address indexed buyer, uint256 coverageAmount);
    event CoverClaimed(uint256 indexed coverId, address indexed buyer);
    event ClaimPaid(uint256 indexed coverId, uint256 payout);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CLAIMS_ROLE, admin);
    }

    function buy_cover(uint256 coverageAmount) external payable whenNotPaused returns (uint256 coverId) {
        require(msg.value > 0, "Premium required");
        coverId = nextCoverId++;
        covers[coverId] = Cover({
            buyer: msg.sender,
            premium: msg.value,
            coverageAmount: coverageAmount,
            active: true,
            claimed: false
        });
        emit CoverPurchased(coverId, msg.sender, coverageAmount);
    }

    function claim_cover(uint256 coverId) external whenNotPaused {
        Cover storage cover = covers[coverId];
        require(cover.buyer == msg.sender, "Not owner");
        require(cover.active && !cover.claimed, "Invalid cover");
        cover.claimed = true;
        emit CoverClaimed(coverId, msg.sender);
    }

    function payout_claim(uint256 coverId, uint256 payoutAmount) external onlyRole(CLAIMS_ROLE) nonReentrant {
        Cover storage cover = covers[coverId];
        require(cover.claimed, "Claim not submitted");
        require(address(this).balance >= payoutAmount, "Insufficient liquidity");
        cover.active = false;
        payable(cover.buyer).transfer(payoutAmount);
        emit ClaimPaid(coverId, payoutAmount);
    }
}
