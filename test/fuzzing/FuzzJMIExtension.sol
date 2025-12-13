// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/preconditions/PreconditionsJMIExtension.sol";
import "./helpers/postconditions/PostconditionsJMIExtension.sol";

contract FuzzJMIExtension is PreconditionsJMIExtension, PostconditionsJMIExtension {
    /**
     * @notice Fuzz handler for JMIExtension.setAssetCap
     * @dev Admin function to set asset cap for a given asset
     */
    function fuzz_JMI_setAssetCap(
        uint256 assetSeed,
        uint256 capSeed
    ) public setCurrentActor {
        JMI_SetAssetCapParams memory params = jmi_setAssetCapPreconditions(
            assetSeed,
            capSeed
        );

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(params.instance).call(
            abi.encodeWithSelector(
                JMIExtension.setAssetCap.selector,
                params.asset,
                params.cap
            )
        );

        jmi_setAssetCapPostconditions(success, returnData, params);
    }

    /**
     * @notice Fuzz handler for JMIExtension.pause (via Pausable)
     * @dev Pauser role function to pause the JMI extension
     */
    function fuzz_JMI_pause(uint256 instanceSeed) public setCurrentActor {
        JMI_PauseParams memory params = jmi_pausePreconditions(instanceSeed);

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(params.instance).call(
            abi.encodeWithSignature("pause()")
        );

        jmi_pausePostconditions(success, returnData);
    }

    /**
     * @notice Fuzz handler for JMIExtension.unpause (via Pausable)
     * @dev Pauser role function to unpause the JMI extension
     */
    function fuzz_JMI_unpause(uint256 instanceSeed) public setCurrentActor {
        JMI_PauseParams memory params = jmi_unpausePreconditions(instanceSeed);

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(params.instance).call(
            abi.encodeWithSignature("unpause()")
        );

        jmi_unpausePostconditions(success, returnData);
    }

    /**
     * @notice Fuzz handler for JMIExtension.freeze (via Freezable)
     * @dev Freeze manager role function to freeze an account
     */
    function fuzz_JMI_freeze(uint256 instanceSeed, uint256 accountSeed) public setCurrentActor {
        JMI_FreezeParams memory params = jmi_freezePreconditions(instanceSeed, accountSeed);

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(params.instance).call(
            abi.encodeWithSignature("freeze(address)", params.account)
        );

        jmi_freezePostconditions(success, returnData, params);
    }

    /**
     * @notice Fuzz handler for JMIExtension.unfreeze (via Freezable)
     * @dev Freeze manager role function to unfreeze an account
     */
    function fuzz_JMI_unfreeze(uint256 instanceSeed, uint256 accountSeed) public setCurrentActor {
        JMI_UnfreezeParams memory params = jmi_unfreezePreconditions(instanceSeed, accountSeed);

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(params.instance).call(
            abi.encodeWithSignature("unfreeze(address)", params.account)
        );

        jmi_unfreezePostconditions(success, returnData, params);
    }
}
