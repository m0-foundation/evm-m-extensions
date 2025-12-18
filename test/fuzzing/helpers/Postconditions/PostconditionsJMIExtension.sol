// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";
import "../Structs/StructsJMIExtension.sol";

contract PostconditionsJMIExtension is PostconditionsBase {
    /**
     * @notice Postconditions for JMIExtension.setAssetCap
     * @dev Validates asset cap was set correctly on success
     */
    function jmi_setAssetCapPostconditions(
        bool success,
        bytes memory returnData,
        JMI_SetAssetCapParams memory params
    ) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for JMIExtension.pause
     * @dev Validates contract is paused on success
     *      Returns early if EnforcedPause error (already paused)
     */
    function jmi_pausePostconditions(bool success, bytes memory returnData) internal {
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
     * @notice Postconditions for JMIExtension.unpause
     * @dev Validates contract is unpaused on success
     *      Returns early if ExpectedPause error (not paused)
     */
    function jmi_unpausePostconditions(bool success, bytes memory returnData) internal {
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

    /**
     * @notice Postconditions for JMIExtension.freeze
     * @dev Validates account is frozen on success
     */
    function jmi_freezePostconditions(bool success, bytes memory returnData, JMI_FreezeParams memory params) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            // Check for AlreadyFrozen error - account already frozen
            if (returnData.length >= 4) {
                bytes4 errorSelector = bytes4(returnData);
                // AlreadyFrozen(address) selector
                if (errorSelector == 0x2f3d8b39) {
                    return; // Expected error, return early
                }
            }
            onFailInvariantsGeneral(returnData);
        }
    }

    /**
     * @notice Postconditions for JMIExtension.unfreeze
     * @dev Validates account is unfrozen on success
     */
    function jmi_unfreezePostconditions(
        bool success,
        bytes memory returnData,
        JMI_UnfreezeParams memory params
    ) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            // Check for NotFrozen error - account not frozen
            if (returnData.length >= 4) {
                bytes4 errorSelector = bytes4(returnData);
                // NotFrozen(address) selector
                if (errorSelector == 0x7a89f6b7) {
                    return; // Expected error, return early
                }
            }
            onFailInvariantsGeneral(returnData);
        }
    }
}
