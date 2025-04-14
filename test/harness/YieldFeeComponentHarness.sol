// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { YieldFeeComponent } from "../../src/abstract/YieldFeeComponent.sol";

contract YieldFeeComponentHarness is YieldFeeComponent {
    constructor(
        uint16 yieldFeeRate_,
        address yieldFeeRecipient_,
        address admin_,
        address yieldFeeManager_
    ) YieldFeeComponent(yieldFeeRate_, yieldFeeRecipient_, admin_, yieldFeeManager_) {}

    function getAccruedYield(
        uint240 balance_,
        uint112 principal_,
        uint128 currentIndex_
    ) external view returns (uint240 yield_, uint240 yieldFee_) {
        return _getAccruedYield(balance_, principal_, currentIndex_);
    }

    function setAccruedYieldFee(address yieldFeeRecipient_, uint256 yield_) external {
        _accruedYieldFee[yieldFeeRecipient_] = yield_;
    }
}
