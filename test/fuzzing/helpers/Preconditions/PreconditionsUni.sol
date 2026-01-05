// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";
import { IUniswapV3Pool } from "uniswapv3/v3-core/interfaces/IUniswapV3Pool.sol";

contract PreconditionsUni is PreconditionsBase {
    function allLiquidityUniPreconditions(
        uint256 amount0Seed,
        uint256 amount1Seed,
        int24 tickLowerSeed,
        int24 tickUpperSeed,
        uint256 strategySeed
    ) internal returns (uint256 amount0Desired, uint256 amount1Desired, int24 tickLower, int24 tickUpper) {
        // Ensure amounts are reasonable
        amount0Desired = fl.clamp(amount0Seed, 0.01e6, 1_000_000e6, true); // 1k to 1M USDC
        amount1Desired = fl.clamp(amount1Seed, 0.01e6, 1_000_000e6, true);

        int24 tickSpacing = 1; // fee tier 100 (0.01%) has tick spacing of 1

        // Use amount0Seed to determine liquidity provision strategy
        uint256 strategy = fl.clamp(strategySeed, 0, 2, true);

        if (strategy == 0) {
            // Add liquidity around current tick
            (, int24 currentTick, , , , , ) = IUniswapV3Pool(address(usdcMTokenPool)).slot0();

            // Generate range around current tick
            int24 rangeSize = int24(fl.clamp(int256(tickLowerSeed), 10, 500, true)) * tickSpacing;
            tickLower = ((currentTick - rangeSize) / tickSpacing) * tickSpacing;
            tickUpper = ((currentTick + rangeSize) / tickSpacing) * tickSpacing;

            console.log("Strategy: Around current tick", int256(currentTick));
        } else if (strategy == 1) {
            // Add liquidity on random range
            // Generate random ticks within valid bounds
            // Valid tick range is -887272 to 887272
            // Map seed to this range more clearly
            int24 tick1 = int24(int256(tickLowerSeed % 1774545)) - 887272;
            int24 tick2 = int24(int256(tickUpperSeed % 1774545)) - 887272;

            // Round to tick spacing
            tick1 = (tick1 / tickSpacing) * tickSpacing;
            tick2 = (tick2 / tickSpacing) * tickSpacing;

            // Ensure proper ordering
            tickLower = tick1 < tick2 ? tick1 : tick2;
            tickUpper = tick1 < tick2 ? tick2 : tick1;

            console.log("Strategy: Random range");
        } else {
            // strategy == 2: Add liquidity on full range
            tickLower = -887220; // Closest to min tick divisible by 10
            tickUpper = 887220; // Closest to max tick divisible by 10

            console.log("Strategy: Full range");
        }

        // Ensure minimum tick range for non-full range positions
        if (strategy != 2 && tickUpper - tickLower < 10 * tickSpacing) {
            tickUpper = tickLower + 10 * tickSpacing;
        }

        // Ensure ticks are within Uniswap V3 bounds
        if (tickLower < -887270) tickLower = -887270;
        if (tickUpper > 887270) tickUpper = 887270;

        (, int24 currentTick, , , , , ) = usdcMTokenPool.slot0();
        console.log("currentTick:", currentTick);

        console.log("Adding liquidity: USDC", amount0Desired);
        console.log("Adding liquidity: WETH", amount1Desired);
        console.log("Tick range lower:", int256(tickLower));
        console.log("Tick range upper:", int256(tickUpper));
    }

    function swapZeroToOnePreconditions(uint256 amountInSeed) internal returns (uint256 amountIn) {
        // Clamp swap amount to reasonable range
        amountIn = fl.clamp(amountInSeed, 100e6, 100_000_000e6, true); // 100 to 100M USDC

        (, int24 currentTick, , , , , ) = usdcMTokenPool.slot0();
        console.log("swapZeroToOne currentTick:", currentTick);

        console.log("Swapping USDC for WETH, amount:", amountIn);
    }

    function swapOneToZeroPreconditions(uint256 amountInSeed) internal returns (uint256 amountIn) {
        // Clamp swap amount to reasonable range
        amountIn = fl.clamp(amountInSeed, 0.01e6, 100_000_000e6, true);

        (, int24 currentTick, , , , , ) = usdcMTokenPool.slot0();
        console.log("swapOneToZero currentTick:", currentTick);

        console.log("Swapping WETH for USDC, amount:", amountIn);
    }
}
