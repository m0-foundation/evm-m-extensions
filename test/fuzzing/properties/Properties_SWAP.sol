// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Properties_ERR.sol";

contract Properties_SWAP is Properties_ERR {
    function invariant_SWAP_01(SwapParams memory params) internal returns (bool) {
        if (params.swapType == uint8(SwapType.YTO_TO_YTO)) {
            uint256 yieldExtA = states[0].mYieldToOne[params.extensionIn].yield;
            uint256 yieldExtB = states[0].mYieldToOne[params.extensionOut].yield;
            uint256 yieldExtAAfter = states[1].mYieldToOne[params.extensionIn].yield;
            uint256 yieldExtBAfter = states[1].mYieldToOne[params.extensionOut].yield;
            fl.eq(yieldExtA, yieldExtAAfter, SWAP_01);
            fl.eq(yieldExtB, yieldExtBAfter, SWAP_01);
        } else if (params.swapType == uint8(SwapType.YFEE_TO_YFEE)) {
            uint256 yieldExtA = states[0].mYieldFee[params.extensionIn].totalAccruedYield;
            uint256 yieldExtB = states[0].mYieldFee[params.extensionOut].totalAccruedYield;
            uint256 yieldExtAAfter = states[1].mYieldFee[params.extensionIn].totalAccruedYield;
            uint256 yieldExtBAfter = states[1].mYieldFee[params.extensionOut].totalAccruedYield;
            fl.eq(yieldExtA, yieldExtAAfter, SWAP_02);
            fl.eq(yieldExtB, yieldExtBAfter, SWAP_02);
        } else if (params.swapType == uint8(SwapType.MEARN_TO_MEARN)) {
            uint256 yieldExtA = states[0].mEarnerManager[params.extensionIn].yield;
            uint256 yieldExtB = states[0].mEarnerManager[params.extensionOut].yield;
            uint256 yieldExtAAfter = states[1].mEarnerManager[params.extensionIn].yield;
            uint256 yieldExtBAfter = states[1].mEarnerManager[params.extensionOut].yield;
            fl.eq(yieldExtA, yieldExtAAfter, SWAP_03);
            fl.eq(yieldExtB, yieldExtBAfter, SWAP_03);
        }
    }

    function invariant_SWAP_02() internal returns (bool) {
        fl.eq(states[1].swapFacilityBalanceOfM0, 0, SWAP_02);
    }
}
