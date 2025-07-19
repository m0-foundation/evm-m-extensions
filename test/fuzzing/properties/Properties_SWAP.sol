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
            assertApproxEqAbs(yieldExtA, yieldExtAAfter, 1, SWAP_01_00);
            assertApproxEqAbs(yieldExtB, yieldExtBAfter, 1, SWAP_01_00);
        } else if (params.swapType == uint8(SwapType.YFEE_TO_YFEE)) {
            uint256 yieldExtA = states[0].mYieldFee[params.extensionIn].totalAccruedYield;
            uint256 yieldExtB = states[0].mYieldFee[params.extensionOut].totalAccruedYield;
            uint256 yieldExtAAfter = states[1].mYieldFee[params.extensionIn].totalAccruedYield;
            uint256 yieldExtBAfter = states[1].mYieldFee[params.extensionOut].totalAccruedYield;
            assertApproxEqAbs(yieldExtA, yieldExtAAfter, 1, SWAP_01_01);
            assertApproxEqAbs(yieldExtB, yieldExtBAfter, 1, SWAP_01_01);
        } else if (params.swapType == uint8(SwapType.MEARN_TO_MEARN)) {
            uint256 yieldExtA = states[0].mEarnerManager[params.extensionIn].yield;
            uint256 yieldExtB = states[0].mEarnerManager[params.extensionOut].yield;
            uint256 yieldExtAAfter = states[1].mEarnerManager[params.extensionIn].yield;
            uint256 yieldExtBAfter = states[1].mEarnerManager[params.extensionOut].yield;
            assertApproxEqAbs(yieldExtA, yieldExtAAfter, 1, SWAP_01_02);
            assertApproxEqAbs(yieldExtB, yieldExtBAfter, 1, SWAP_01_02);
        }
    }

    function invariant_SWAP_02() internal returns (bool) {
        fl.eq(states[1].swapFacilityBalanceOfM0, 0, SWAP_02);
    }

    function invariant_SWAP_03() internal returns (bool) {
        for (uint256 i = 0; i < USERS.length; i++) {
            fl.eq(
                states[0].actorStates[USERS[i]].totalM0Balance,
                states[1].actorStates[USERS[i]].totalM0Balance,
                SWAP_03
            );
        }
    }

    function invariant_SWAP_04(SwapInTokenParams memory params) internal returns (bool) {
        console.log("actor", currentActor);
        console.log("before", states[0].actorStates[currentActor].totalM0Balance);
        console.log("after", states[1].actorStates[currentActor].totalM0Balance);
        console.log("minAmountOut", params.minAmountOut);
        console.log("received", states[1].actorStates[currentActor].totalM0Balance - params.minAmountOut);
        console.log("slippage", states[0].actorStates[currentActor].totalM0Balance);
        fl.gte(
            states[1].actorStates[currentActor].totalM0Balance - params.minAmountOut, //received amount of M0 should be greater or equal than slippage
            states[0].actorStates[currentActor].totalM0Balance,
            SWAP_04
        );
    }

    function invariant_SWAP_05(SwapOutTokenParams memory params) internal returns (bool) {
        console.log("actor", currentActor);
        console.log("before", states[0].actorStates[currentActor].totalM0Balance);
        console.log("after", states[1].actorStates[currentActor].totalM0Balance);
        console.log("minAmountOut", params.minAmountOut);
        console.log("received", states[1].actorStates[currentActor].totalM0Balance - params.minAmountOut);
        console.log("slippage", states[0].actorStates[currentActor].totalM0Balance);
        fl.gte(
            states[1].actorStates[currentActor].usdcBalance,
            states[0].actorStates[currentActor].usdcBalance + params.minAmountOut,
            SWAP_05
        );
    }
}
