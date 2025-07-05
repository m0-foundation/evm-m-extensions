// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./PostconditionsBase.sol";

contract PostconditionsSwapFacility is PostconditionsBase {
    function swapPostconditions(bool success, bytes memory returnData, SwapParams memory params) internal {
        if (success) {
            _after();
            invariant_SWAP_01(params);
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function swapInMPostconditions(bool success, bytes memory returnData, SwapInMParams memory params) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function swapOutMPostconditions(bool success, bytes memory returnData, SwapOutMParams memory params) internal {
        if (success) {
            _after();

            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function swapInTokenPostconditions(
        bool success,
        bytes memory returnData,
        SwapInTokenParams memory params
    ) internal {
        if (success) {
            _after();

            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function swapOutTokenPostconditions(
        bool success,
        bytes memory returnData,
        SwapOutTokenParams memory params
    ) internal {
        if (success) {
            _after();

            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
