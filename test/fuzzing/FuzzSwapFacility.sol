// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PreconditionsSwapFacility } from "./helpers/Preconditions/PreconditionsSwapFacility.sol";
import { PostconditionsSwapFacility } from "./helpers/Postconditions/PostconditionsSwapFacility.sol";

contract FuzzSwapFacility is PreconditionsSwapFacility, PostconditionsSwapFacility {
    /**
     * @notice Fuzz handler for SwapFacility.swap
     * @dev Main swap function for swapping between tokens/extensions
     */
    function fuzz_SF_swap(
        uint256 tokenInSeed,
        uint256 tokenOutSeed,
        uint256 amountSeed,
        uint256 recipientSeed
    ) public setCurrentActor {
        SF_SwapParams memory params = sf_swapPreconditions(
            tokenInSeed,
            tokenOutSeed,
            amountSeed,
            recipientSeed
        );

        // Return early if preconditions returned empty params (contracts paused)
        if (params.tokenIn == address(0)) {
            return;
        }

        // Check if currentActor has sufficient balance, mint if needed
        uint256 balance = IERC20(params.tokenIn).balanceOf(currentActor);
        if (balance < params.amount) {
            // Only mint if tokenIn is a base token (not an extension)
            // For extensions, skip the swap if insufficient balance
            bool isExtension = false;
            for (uint256 i = 0; i < allExtensions.length; i++) {
                if (params.tokenIn == allExtensions[i]) {
                    isExtension = true;
                    break;
                }
            }

            if (isExtension) {
                return; // Can't mint extension tokens directly
            } else {
                // Mint base token to currentActor
                uint256 amountToMint = params.amount - balance;
                MockERC20(params.tokenIn).mint(currentActor, amountToMint);
            }
        }

        // For extension tokenIn, check M backing is sufficient
        // Use 90% of balance to account for yield accrual difference
        for (uint256 i = 0; i < allExtensions.length; i++) {
            if (params.tokenIn == allExtensions[i]) {
                uint256 mBacking = (mToken.balanceOf(params.tokenIn) * 90) / 100;
                if (mBacking < params.amount) {
                    return; // Insufficient M backing
                }
                break;
            }
        }

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(swapFacility).call(
            abi.encodeWithSelector(
                SwapFacility.swap.selector,
                params.tokenIn,
                params.tokenOut,
                params.amount,
                params.recipient
            )
        );

        sf_swapPostconditions(success, returnData, params);
    }

    /**
     * @notice Fuzz handler for SwapFacility.replaceAssetWithM
     * @dev Replaces asset in JMI extension with M token
     */
    function fuzz_SF_replaceAssetWithM(
        uint256 assetSeed,
        uint256 extensionInSeed,
        uint256 extensionOutSeed,
        uint256 amountSeed,
        uint256 recipientSeed
    ) public setCurrentActor {
        SF_ReplaceAssetWithMParams memory params = sf_replaceAssetWithMPreconditions(
            assetSeed,
            extensionInSeed,
            extensionOutSeed,
            amountSeed,
            recipientSeed
        );

        // Return early if preconditions returned empty params (contracts paused)
        if (params.asset == address(0)) {
            return;
        }

        // Return early if user doesn't have enough extensionIn balance
        uint256 userBalance = IERC20(params.extensionIn).balanceOf(currentActor);
        if (userBalance < params.amount) {
            return;
        }

        // Return early if extensionIn doesn't have enough M backing
        // Use 90% of balance to account for yield accrual difference
        uint256 mBacking = (mToken.balanceOf(params.extensionIn) * 90) / 100;
        if (mBacking < params.amount) {
            return;
        }

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(swapFacility).call(
            abi.encodeWithSelector(
                SwapFacility.replaceAssetWithM.selector,
                params.asset,
                params.extensionIn,
                params.extensionOut,
                params.amount,
                params.recipient
            )
        );

        sf_replaceAssetWithMPostconditions(success, returnData, params);
    }

    /**
     * @notice Fuzz handler for SwapFacility.setPermissionedExtension
     * @dev Admin function to set whether an extension is permissioned
     */
    function fuzz_SF_setPermissionedExtension(
        uint256 extensionSeed,
        uint256 permissionedSeed
    ) public setCurrentActor {
        SF_SetPermissionedExtensionParams memory params = sf_setPermissionedExtensionPreconditions(
            extensionSeed,
            permissionedSeed
        );

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(swapFacility).call(
            abi.encodeWithSelector(
                SwapFacility.setPermissionedExtension.selector,
                params.extension,
                params.permissionedSeed % 2 == 0 // Convert to bool
            )
        );

        sf_setPermissionedExtensionPostconditions(success, returnData, params);
    }

    /**
     * @notice Fuzz handler for SwapFacility.setPermissionedMSwapper
     * @dev Admin function to set whether a swapper is allowed for a permissioned extension
     */
    function fuzz_SF_setPermissionedMSwapper(
        uint256 extensionSeed,
        uint256 swapperSeed,
        uint256 allowedSeed
    ) public setCurrentActor {
        SF_SetPermissionedMSwapperParams memory params = sf_setPermissionedMSwapperPreconditions(
            extensionSeed,
            swapperSeed,
            allowedSeed
        );

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(swapFacility).call(
            abi.encodeWithSelector(
                SwapFacility.setPermissionedMSwapper.selector,
                params.extension,
                params.swapper,
                params.allowedSeed % 2 == 0 // Convert to bool
            )
        );

        sf_setPermissionedMSwapperPostconditions(success, returnData, params);
    }

    /**
     * @notice Fuzz handler for SwapFacility.setAdminApprovedExtension
     * @dev Admin function to set whether an extension is admin-approved
     */
    function fuzz_SF_setAdminApprovedExtension(
        uint256 extensionSeed,
        uint256 approvedSeed
    ) public setCurrentActor {
        SF_SetAdminApprovedExtensionParams memory params = sf_setAdminApprovedExtensionPreconditions(
            extensionSeed,
            approvedSeed
        );

        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(swapFacility).call(
            abi.encodeWithSelector(
                SwapFacility.setAdminApprovedExtension.selector,
                params.extension,
                params.approvedSeed % 2 == 0 // Convert to bool
            )
        );

        sf_setAdminApprovedExtensionPostconditions(success, returnData, params);
    }

    /**
     * @notice Fuzz handler for SwapFacility.pause (via Pausable)
     * @dev Pauser role function to pause the swap facility
     */
    function fuzz_SF_pause(uint256 instanceSeed) public setCurrentActor {
        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(swapFacility).call(
            abi.encodeWithSignature("pause()")
        );

        sf_pausePostconditions(success, returnData);
    }

    /**
     * @notice Fuzz handler for SwapFacility.unpause (via Pausable)
     * @dev Pauser role function to unpause the swap facility
     */
    function fuzz_SF_unpause(uint256 instanceSeed) public setCurrentActor {
        _before();

        vm.prank(currentActor);
        (bool success, bytes memory returnData) = address(swapFacility).call(
            abi.encodeWithSignature("unpause()")
        );

        sf_unpausePostconditions(success, returnData);
    }
}
