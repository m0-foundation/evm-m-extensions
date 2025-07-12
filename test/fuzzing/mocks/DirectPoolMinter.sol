// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IUniswapV3Pool } from "uniswapv3/v3-core/interfaces/IUniswapV3Pool.sol";
import { IERC20Minimal } from "uniswapv3/v3-core/interfaces/IERC20Minimal.sol";

import { IUniswapV3MintCallback } from "uniswapv3/v3-core/interfaces/callback/IUniswapV3MintCallback.sol";

import "uniswapv3/v3-periphery/libraries/LiquidityAmounts.sol";
import "uniswapv3/v3-core/libraries/TickMath.sol";
import { console } from "forge-std/console.sol";

contract DirectPoolMinter is IUniswapV3MintCallback {
    using TickMath for int24;

    IUniswapV3Pool public pool;
    address public immutable token0;
    address public immutable token1;

    constructor(address _pool) {
        pool = IUniswapV3Pool(_pool);
        token0 = pool.token0();
        token1 = pool.token1();
    }

    // Callback function required by Uniswap V3 pool
    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external override {
        // Ensure the caller is the Uniswap V3 pool
        require(msg.sender == address(pool), "Invalid caller");

        // Transfer tokens to the pool
        if (amount0Owed > 0) {
            IERC20Minimal(token0).transfer(address(pool), amount0Owed);
        }
        if (amount1Owed > 0) {
            IERC20Minimal(token1).transfer(address(pool), amount1Owed);
        }
    }

    // Function to mint liquidity directly in the pool
    function mintLiquidity(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 amount0Max,
        uint256 amount1Max
    ) external returns (uint256 amount0, uint256 amount1) {
        // Approve tokens to the pool
        IERC20Minimal(token0).approve(address(pool), amount0Max);
        IERC20Minimal(token1).approve(address(pool), amount1Max);

        IERC20Minimal(token0).transferFrom(msg.sender, address(this), amount0Max);
        IERC20Minimal(token1).transferFrom(msg.sender, address(this), amount1Max);

        // Call the mint function on the pool
        (amount0, amount1) = pool.mint(recipient, tickLower, tickUpper, liquidity, abi.encode(msg.sender));

        // Refund any excess tokens (optional)
        if (amount0 < amount0Max) {
            IERC20Minimal(token0).approve(address(pool), 0);
            IERC20Minimal(token0).transfer(msg.sender, amount0Max - amount0);
        }
        if (amount1 < amount1Max) {
            IERC20Minimal(token1).approve(address(pool), 0);
            IERC20Minimal(token1).transfer(msg.sender, amount1Max - amount1);
        }
    }

    // Helper function to calculate liquidity from token amounts
    function getLiquidityForAmounts(
        uint256 amount0Desired,
        uint256 amount1Desired,
        int24 tickLower,
        int24 tickUpper
    ) public returns (uint128 liquidity) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        console.log("sqrtPriceX96", sqrtPriceX96);

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        console.log("sqrtRatioAX96", uint256(sqrtRatioAX96));
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        console.log("sqrtRatioBX96", uint256(sqrtRatioBX96));

        console.log("amount0Desired", amount0Desired);
        console.log("amount1Desired", amount1Desired);

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            amount0Desired,
            amount1Desired
        );
        console.log("liquidity", liquidity);
    }
}
