// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./PreconditionsBase.sol";

contract PreconditionsSwapFacility is PreconditionsBase {
    function swapPreconditions(uint256 seed) internal returns (SwapParams memory params) {
        params.instance = address(swapFacility);
        params.extensionIn = allExtensions[seed % allExtensions.length];
        params.extensionOut = allExtensions[(seed / 2 + 1) % allExtensions.length];
        params.amount = seed;
        params.recipient = currentActor;
        params.swapType = uint8(_getSwapType(params.extensionIn, params.extensionOut));
    }

    function swapInMPreconditions(uint256 seed) internal returns (SwapInMParams memory params) {
        params.instance = address(swapFacility);
        params.extensionOut = allExtensions[seed % allExtensions.length];
        params.amount = seed;
        params.recipient = currentActor;
    }

    function swapOutMPreconditions(uint256 seed) internal returns (SwapOutMParams memory params) {
        params.instance = address(swapFacility);
        params.extensionIn = allExtensions[seed % allExtensions.length];
        params.amount = seed;
        params.recipient = currentActor;
    }

    function swapInTokenPreconditions(uint256 seed) internal returns (SwapInTokenParams memory params) {
        params.instance = address(swapAdapter);
        params.tokenIn = address(USDC);
        params.amountIn = fl.clamp(seed, 0, USDC.balanceOf(currentActor));
        params.extensionOut = allExtensions[seed % allExtensions.length];
        params.minAmountOut = 0; // params.amountIn / 2; //NOTE: revise if needed
        params.recipient = currentActor;
        params.path = new bytes(0);
    }

    function swapOutTokenPreconditions(uint256 seed) internal returns (SwapOutTokenParams memory params) {
        params.instance = address(swapAdapter);
        params.extensionIn = allExtensions[seed % allExtensions.length];
        params.amountIn = fl.clamp(seed, 0, IMTokenLike(params.extensionIn).balanceOf(currentActor));
        params.tokenOut = address(USDC);
        params.minAmountOut = params.amountIn / 2;
        params.recipient = currentActor;
        params.path = new bytes(0);
    }

    function _getSwapType(address extensionIn, address extensionOut) internal view returns (SwapType) {
        uint8 typeIn = _getExtensionType(extensionIn);
        uint8 typeOut = _getExtensionType(extensionOut);

        // YTO = 0, YFEE = 1, MEARN = 2
        if (typeIn == 0 && typeOut == 0) return SwapType.YTO_TO_YTO;
        if (typeIn == 0 && typeOut == 1) return SwapType.YTO_TO_YFEE;
        if (typeIn == 0 && typeOut == 2) return SwapType.YTO_TO_MEARN;
        if (typeIn == 1 && typeOut == 0) return SwapType.YFEE_TO_YTO;
        if (typeIn == 1 && typeOut == 1) return SwapType.YFEE_TO_YFEE;
        if (typeIn == 1 && typeOut == 2) return SwapType.YFEE_TO_MEARN;
        if (typeIn == 2 && typeOut == 0) return SwapType.MEARN_TO_YTO;
        if (typeIn == 2 && typeOut == 1) return SwapType.MEARN_TO_YFEE;
        if (typeIn == 2 && typeOut == 2) return SwapType.MEARN_TO_MEARN;

        return SwapType.NA;
    }

    function _getExtensionType(address extension) internal view returns (uint8) {
        // allExtensions array structure:
        // [0,3,6] = YTO (MYieldToOne), [1,4,7] = YFEE (MYieldFee), [2,5,8] = MEARN (MEarnerManager)
        for (uint8 i = 0; i < allExtensions.length; i++) {
            if (allExtensions[i] == extension) {
                return i % 3; // 0=YTO, 1=YFEE, 2=MEARN
            }
        }
        return 255; // Not found
    }
}
