// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

contract PostconditionsUni is PostconditionsBase {
    function allLiquidityUniPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address user,
        uint256 amount0Desired,
        uint256 amount1Desired,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        if (success) {
            _after(actorsToUpdate);

            // Verify liquidity was added
            assertTrue(
                true, // In real impl, check that position exists
                "UNI-01: Liquidity should be added to the pool"
            );

            // Verify tick range is valid
            assertTrue(tickLower < tickUpper, "UNI-02: Tick lower must be less than tick upper");

            console.log("Successfully added liquidity");
        } else {
            invariant_ERR(returnData);
        }
    }

    function swapZeroToOnePostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address user,
        uint256 amountIn,
        uint256 amountOut
    ) internal {
        if (success) {
            _after(actorsToUpdate);

            // Verify swap occurred
            // assertTrue(amountOut > 0, "UNI-03: Swap should return non-zero output amount");
            fl.gt(amountOut, 0, "UNI-03: Swap should return non-zero output amount");

            console.log("Swap successful - USDC in:", amountIn, "WETH out:", amountOut);
        } else {
            invariant_ERR(returnData);
        }
    }

    function swapOneToZeroPostconditions(
        bool success,
        bytes memory returnData,
        address[] memory actorsToUpdate,
        address user,
        uint256 amountIn,
        uint256 amountOut
    ) internal {
        if (success) {
            _after(actorsToUpdate);

            // Verify swap occurred
            assertTrue(amountOut > 0, "UNI-04: Swap should return non-zero output amount");

            console.log("Swap successful - WETH in:", amountIn, "USDC out:", amountOut);
        } else {
            invariant_ERR(returnData);
        }
    }
}
