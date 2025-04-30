// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { YieldFee } from "../../src/abstract/components/YieldFee.sol";

contract YieldFeeHarness is YieldFee {
    constructor(
        uint16 yieldFeeRate_,
        address yieldFeeRecipient_,
        address admin_,
        address yieldFeeManager_
    ) YieldFee(yieldFeeRate_, yieldFeeRecipient_, admin_, yieldFeeManager_) {}
}
