// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldFee } from "../../src/MYieldFee.sol";

contract MYieldFeeHarness is MYieldFee {
    constructor(
        string memory name_,
        string memory symbol_,
        address mToken_,
        address registrar_,
        uint16 yieldFeeRate_,
        address yieldFeeRecipient_,
        address admin_,
        address yieldFeeManager_
    ) MYieldFee(name_, symbol_, mToken_, registrar_, yieldFeeRate_, yieldFeeRecipient_, admin_, yieldFeeManager_) {}

    function setAccountOf(address account_, uint240 balance_, uint112 principal_, uint128 lastClaimIndex_) external {
        _accounts[account_].balance = balance_;
        _accounts[account_].principal = principal_;
        _accounts[account_].lastClaimIndex = lastClaimIndex_;
    }

    function setEnableMIndex(uint256 enableMIndex_) external {
        enableMIndex = uint128(enableMIndex_);
    }

    function setDisableIndex(uint256 disableIndex_) external {
        disableIndex = uint128(disableIndex_);
    }

    function setLastYieldFeeClaimIndex(uint128 lastYieldFeeClaimIndex_) external {
        lastYieldFeeClaimIndex = lastYieldFeeClaimIndex_;
    }
    function setTotalSupply(uint256 totalSupply_) external {
        totalSupply = totalSupply_;
    }

    function setTotalPrincipal(uint112 totalPrincipal_) external {
        totalPrincipal = totalPrincipal_;
    }
}
