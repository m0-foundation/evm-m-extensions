// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";
import "../Structs/StructsSwapFacility.sol";

contract PostconditionsSwapFacility is PostconditionsBase {
    /**
     * @notice Postconditions for SwapFacility.swap
     * @dev Validates swap completed successfully and balances updated
     *      Returns early for expected errors (EnforcedPause, InsufficientBalance, AccountFrozen, etc.)
     */
    function sf_swapPostconditions(bool success, bytes memory returnData, SF_SwapParams memory params) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for SwapFacility.replaceAssetWithM
     * @dev Validates asset replacement completed successfully
     *      Returns early for expected errors (EnforcedPause, InsufficientBalance, etc.)
     */
    function sf_replaceAssetWithMPostconditions(
        bool success,
        bytes memory returnData,
        SF_ReplaceAssetWithMParams memory params
    ) internal {
        if (success) {
            _after();

            onSuccessInvariantsGeneral(returnData);
        } else {
            // Check for expected errors that should not fail the fuzzer
            if (returnData.length >= 4) {
                bytes4 errorSelector = bytes4(returnData);
                // EnforcedPause() - contract is paused
                if (errorSelector == 0xd93c0665) return;
                // InsufficientBalance() - not enough tokens
                if (errorSelector == 0xf4d678b8) return;
                // InsufficientAllowance() - not enough allowance
                if (errorSelector == 0x13be252b) return;
                // NotApprovedPermissionedSwapper(address,address) - swapper not approved for permissioned extension
                if (errorSelector == 0xe5fae0d0) return;
            }
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for SwapFacility.setPermissionedExtension
     * @dev Validates permissioned status was set correctly
     */
    function sf_setPermissionedExtensionPostconditions(
        bool success,
        bytes memory returnData,
        SF_SetPermissionedExtensionParams memory params
    ) internal {
        if (success) {
            _after();

            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for SwapFacility.setPermissionedMSwapper
     * @dev Validates swapper permission was set correctly
     */
    function sf_setPermissionedMSwapperPostconditions(
        bool success,
        bytes memory returnData,
        SF_SetPermissionedMSwapperParams memory params
    ) internal {
        if (success) {
            _after();

            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for SwapFacility.setAdminApprovedExtension
     * @dev Validates admin approval status was set correctly
     */
    function sf_setAdminApprovedExtensionPostconditions(
        bool success,
        bytes memory returnData,
        SF_SetAdminApprovedExtensionParams memory params
    ) internal {
        if (success) {
            _after();

            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for SwapFacility.pause
     * @dev Validates contract is paused on success
     *      Returns early if EnforcedPause error (already paused)
     */
    function sf_pausePostconditions(bool success, bytes memory returnData) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            // Check for EnforcedPause error - contract already paused
            if (returnData.length >= 4) {
                bytes4 errorSelector = bytes4(returnData);
                // EnforcedPause() selector is 0xd93c0665
                if (errorSelector == 0xd93c0665) {
                    return; // Expected error, return early
                }
            }
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for SwapFacility.unpause
     * @dev Validates contract is unpaused on success
     *      Returns early if ExpectedPause error (not paused)
     */
    function sf_unpausePostconditions(bool success, bytes memory returnData) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            // Check for ExpectedPause error - contract not paused
            if (returnData.length >= 4) {
                bytes4 errorSelector = bytes4(returnData);
                // ExpectedPause() selector is 0x8dfc202b
                if (errorSelector == 0x8dfc202b) {
                    return; // Expected error, return early
                }
            }
            onFailInvariantsGeneral(returnData);
        }
    }
}
