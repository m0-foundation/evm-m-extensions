// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UIntMath } from "../../lib/common/src/libs/UIntMath.sol";

contract Helpers {
    uint16 public constant HUNDRED_PERCENT = 10_000;

    function _getEarnerRate(uint32 mEarnerRate, uint32 yieldFeeRate) internal pure returns (uint32) {
        return UIntMath.safe32((uint256(HUNDRED_PERCENT - yieldFeeRate) * mEarnerRate) / HUNDRED_PERCENT);
    }

    function _getYieldFee(uint240 yield, uint16 yieldFeeRate) internal pure returns (uint240) {
        return yield == 0 ? 0 : (yield * yieldFeeRate) / HUNDRED_PERCENT;
    }
}
