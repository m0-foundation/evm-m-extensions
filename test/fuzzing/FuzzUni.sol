// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { PreconditionsUni } from "./helpers/Preconditions/PreconditionsUni.sol";
import { PostconditionsUni } from "./helpers/Postconditions/PostconditionsUni.sol";

contract FuzzUni is PreconditionsUni, PostconditionsUni {
    // function fuzz_allLiquidityUni(
    //     uint256 amount0Seed,
    //     uint256 amount1Seed,
    //     int24 tickLowerSeed,
    //     int24 tickUpperSeed,
    //     uint256 strategySeed
    // ) public setCurrentActor {
    //     (
    //         uint256 amount0Desired,
    //         uint256 amount1Desired,
    //         int24 tickLower,
    //         int24 tickUpper
    //     ) = allLiquidityUniPreconditions(amount0Seed, amount1Seed, tickLowerSeed, tickUpperSeed, strategySeed);

    //     address[] memory actorsToUpdate = new address[](1);
    //     actorsToUpdate[0] = currentActor;
    //     _before(actorsToUpdate);

    //     add_liquidity_direct(
    //         currentActor,
    //         currentActor,
    //         amount0Desired,
    //         amount1Desired,
    //         tickLower,
    //         tickUpper,
    //         address(usdcMTokenPool)
    //     );

    //     allLiquidityUniPostconditions(
    //         true, // Assuming success for direct liquidity addition
    //         new bytes(0),
    //         actorsToUpdate,
    //         currentActor,
    //         amount0Desired,
    //         amount1Desired,
    //         tickLower,
    //         tickUpper
    //     );
    // }

    function fuzz_swapZeroToOne(uint256 amountInSeed) public setCurrentActor {
        uint256 amountIn = swapZeroToOnePreconditions(amountInSeed);

        address[] memory actorsToUpdate = new address[](1);
        actorsToUpdate[0] = currentActor;
        _before(actorsToUpdate);

        uint256 amountOut = swap_t0_for_t1(currentActor, amountIn);

        swapZeroToOnePostconditions(
            true, // Direct call should succeed
            new bytes(0),
            actorsToUpdate,
            currentActor,
            amountIn,
            amountOut
        );
    }

    // function fuzz_swapOneToZero(uint256 amountInSeed) public setCurrentActor {
    //     uint256 amountIn = swapOneToZeroPreconditions(amountInSeed);

    //     address[] memory actorsToUpdate = new address[](1);
    //     actorsToUpdate[0] = currentActor;
    //     _before(actorsToUpdate);

    //     uint256 amountOut = swap_t1_for_t0(currentActor, amountIn);

    //     swapOneToZeroPostconditions(
    //         true, // Direct call should succeed
    //         new bytes(0),
    //         actorsToUpdate,
    //         currentActor,
    //         amountIn,
    //         amountOut
    //     );
    // }
}
