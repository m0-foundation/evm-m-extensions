// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PreconditionsSwapFacility } from "./helpers/Preconditions/PreconditionsSwapFacility.sol";
import { PostconditionsSwapFacility } from "./helpers/Postconditions/PostconditionsSwapFacility.sol";

contract FuzzSwapFacility is PreconditionsSwapFacility, PostconditionsSwapFacility {
    function fuzz_swap(uint256 seed) public setCurrentActor {
        SwapParams memory params = swapPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _swapCall(
            params.instance,
            params.extensionIn,
            params.extensionOut,
            params.amount,
            params.recipient
        );

        swapPostconditions(success, returnData, params);
    }

    function fuzz_swapInM(uint256 seed) public setCurrentActor {
        SwapInMParams memory params = swapInMPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _swapInMCall(
            params.instance,
            params.extensionOut,
            params.amount,
            params.recipient
        );

        swapInMPostconditions(success, returnData, params);
    }

    function fuzz_swapOutM(uint256 seed) public setCurrentActor {
        SwapOutMParams memory params = swapOutMPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _swapOutMCall(
            params.instance,
            params.extensionIn,
            params.amount,
            params.recipient
        );

        swapOutMPostconditions(success, returnData, params);
    }

    function fuzz_swapInToken(uint256 seed) public setCurrentActor {
        SwapInTokenParams memory params = swapInTokenPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _swapInTokenCall(
            params.instance,
            params.tokenIn,
            params.amountIn,
            params.extensionOut,
            params.minAmountOut,
            params.recipient,
            params.path
        );

        swapInTokenPostconditions(success, returnData, params);
    }

    function fuzz_swapOutToken(uint256 seed) public setCurrentActor {
        SwapOutTokenParams memory params = swapOutTokenPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _swapOutTokenCall(
            params.instance,
            params.extensionIn,
            params.amountIn,
            params.tokenOut,
            params.minAmountOut,
            params.recipient,
            params.path
        );

        swapOutTokenPostconditions(success, returnData, params);
    }
}
