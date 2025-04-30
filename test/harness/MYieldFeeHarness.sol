// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldFee } from "../../src/MYieldFee.sol";

contract MYieldFeeHarness is MYieldFee {
    constructor(
        string memory name,
        string memory symbol,
        address mToken,
        address rateModel,
        uint16 yieldFeeRate,
        address yieldFeeRecipient,
        address admin,
        address yieldFeeManager
    ) MYieldFee(name, symbol, mToken, rateModel, yieldFeeRate, yieldFeeRecipient, admin, yieldFeeManager) {}

    function setAccountOf(address account, uint240 balance, uint112 principal) external {
        _accounts[account].balance = balance;
        _accounts[account].principal = principal;
    }

    function setEnableLatestMIndex(uint256 enableLatestMIndex_) external {
        enableLatestMIndex = uint128(enableLatestMIndex_);
    }

    function setDisableIndex(uint256 disableIndex_) external {
        disableIndex = uint128(disableIndex_);
    }

    function setTotalSupply(uint256 totalSupply_) external {
        totalSupply = totalSupply_;
    }

    function setTotalPrincipal(uint112 totalPrincipal_) external {
        totalPrincipal = totalPrincipal_;
    }
}
