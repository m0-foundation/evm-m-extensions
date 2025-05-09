// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldFee } from "../../src/MYieldFee.sol";

contract MYieldFeeHarness is MYieldFee {
    constructor(
        string memory name,
        string memory symbol,
        address mToken,
        uint16 yieldFeeRate,
        address yieldFeeRecipient,
        address admin,
        address yieldFeeManager
    ) MYieldFee(name, symbol, mToken, yieldFeeRate, yieldFeeRecipient, admin, yieldFeeManager) {}

    function setAccountOf(address account, uint256 balance, uint112 principal) external {
        balanceOf[account] = balance;
        principalOf[account] = principal;
    }

    function setLatestIndex(uint256 latestIndex_) external {
        latestIndex = uint128(latestIndex_);
    }

    function setLatestRate(uint256 latestRate_) external {
        latestRate = uint32(latestRate_);
    }

    function setLatestUpdateTimestamp(uint256 latestUpdateTimestamp_) external {
        latestUpdateTimestamp = uint40(latestUpdateTimestamp_);
    }

    function setTotalSupply(uint256 totalSupply_) external {
        totalSupply = totalSupply_;
    }

    function setTotalPrincipal(uint112 totalPrincipal_) external {
        totalPrincipal = totalPrincipal_;
    }
}
