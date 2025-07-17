// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BeforeAfter.sol";

import { IV3SwapRouter } from "uniswapv3/v3-periphery/interfaces/IV3SwapRouter.sol";

contract PreconditionsBase is BeforeAfter {
    event LogAddress(address actor);

    modifier setCurrentActor() {
        require(protocolSet);

        if (_setActor) {
            uint256 fuzzNumber = generateFuzzNumber(iteration, SEED);
            console.log("fuzz iteration", iteration);
            currentActor = USERS[uint256(keccak256(abi.encodePacked(iteration * PRIME + SEED))) % (USERS.length)];

            iteration += 1;

            // vm.startPrank(currentActor);
            console.log("Pranking: ", toString(currentActor)); //echidna logs output
            console.log("Block timestamp: ", block.timestamp);
            //check state and revert workaround
            if (block.timestamp < lastTimestamp) {
                vm.warp(lastTimestamp);
            } else {
                lastTimestamp = block.timestamp;
            }
        }
        emit LogAddress(currentActor);
        _;
        // vm.stopPrank();
        // console.log("Stopped prank: ", toString(msg.sender));
    }

    function setActor(address targetUser) internal {
        address[] memory targetArray = USERS; //use several arrays
        require(targetArray.length > 0, "Target array is empty");

        // Find target user index
        uint256 targetIndex;
        bool found = false;
        for (uint256 i = 0; i < targetArray.length; i++) {
            if (targetArray[i] == targetUser) {
                targetIndex = i;
                console.log("Setting user", targetUser);
                console.log("Index", i);

                found = true;
                break;
            }
        }

        require(found, "Target user not found in array");

        uint256 maxIterations = 100000; //  prevent infinite loops
        uint256 currentIteration = iteration;
        bool iterationFound = false;

        for (uint256 i = 0; i < maxIterations; i++) {
            uint256 hash = uint256(keccak256(abi.encodePacked(currentIteration * PRIME + SEED)));
            uint256 index = hash % targetArray.length;

            if (index == targetIndex) {
                iteration = currentIteration;
                iterationFound = true;
                break;
            }

            currentIteration++;
        }

        require(iterationFound, "User index not found by setter");
    }

    function generateFuzzNumber(uint256 iteration, uint256 seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(iteration * PRIME + seed)));
    }

    function toString(address value) internal pure returns (string memory str) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(value)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function add_liquidity_direct(
        address user,
        address to,
        uint256 amount0Desired,
        uint256 amount1Desired,
        int24 tickLower,
        int24 tickUpper,
        address pool
    ) public {
        vm.startPrank(user);

        // Calculate liquidity
        uint128 liquidity = minter.getLiquidityForAmounts(amount0Desired, amount1Desired, tickLower, tickUpper);
        require(liquidity > 0, "Invalid liquidity");
        console.log("liquidity check done", liquidity);
        // Approve tokens to the minter
        USDC.approve(address(minter), amount0Desired);
        wMToken.approve(address(minter), amount1Desired);

        // Mint liquidity
        (uint256 amount0, uint256 amount1) = minter.mintLiquidity(
            to, // Recipient of the position
            tickLower,
            tickUpper,
            liquidity,
            amount0Desired, // Max USDC to spend
            amount1Desired // Max wMToken to spend
        );

        // Log results
        console.log("Liquidity minted:", uint256(liquidity));
        console.log("USDC used:", uint256(amount0));
        console.log("wMToken used:", uint256(amount1));

        // Verify position in the pool
        bytes32 positionKey = bytes32(keccak256(abi.encodePacked(user, tickLower, tickUpper)));
        IUniswapV3Pool(pool).positions(positionKey);

        vm.stopPrank();
    }

    /**
     * @notice Swap token0 (USDC) to token1 (wMToken)
     * @param amountIn Amount of USDC to swap
     * @return amountOut Amount of wMToken received from the swap
     */
    function swap_t0_for_t1(address actor, uint256 amountIn) internal returns (uint256 amountOut) {
        console.log("Swapping token0 (USDC) for token1 (wMToken)");
        vm.startPrank(actor);
        // Approve the router to spend token0 (USDC)
        USDC.approve(address(v3SwapRouter), type(uint256).max);

        // Prepare exact input parameters (swapping exact amount of USDC for wMToken)
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: address(USDC),
            tokenOut: address(wMToken),
            fee: UNISWAP_V3_FEE,
            recipient: actor,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0 // No price limit (accept any price)
        });

        // Execute the swap
        amountOut = v3SwapRouter.exactInputSingle(params);

        // Log the results
        console.log("Swap completed:");
        console.log("USDC spent:", amountIn);
        console.log("wMToken received:", amountOut);
        vm.stopPrank();
        return amountOut;
    }

    /**
     * @notice Swap token1 (wMToken) to token0 (USDC)
     * @param amountIn Amount of wMToken to swap
     * @return amountOut Amount of USDC received from the swap
     */
    function swap_t1_for_t0(address actor, uint256 amountIn) internal returns (uint256 amountOut) {
        console.log("Swapping token1 (wMToken) for token0 (USDC)");
        vm.startPrank(actor);
        // Approve the router to spend token1 (wMToken)
        wMToken.approve(address(v3SwapRouter), type(uint256).max);

        // Prepare exact input parameters (swapping exact amount of wMToken for USDC)
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: address(wMToken),
            tokenOut: address(USDC),
            fee: UNISWAP_V3_FEE,
            recipient: actor,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0 // No price limit (accept any price)
        });

        // Execute the swap
        amountOut = v3SwapRouter.exactInputSingle(params);

        // Log the results
        console.log("Swap completed:");
        console.log("wMToken spent:", amountIn);
        console.log("USDC received:", amountOut);
        vm.stopPrank();
        return amountOut;
    }
}
