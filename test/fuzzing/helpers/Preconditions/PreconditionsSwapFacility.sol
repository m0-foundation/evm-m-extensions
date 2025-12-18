// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";
import "../Structs/StructsSwapFacility.sol";

contract PreconditionsSwapFacility is PreconditionsBase {
    /**
     * @notice Preconditions for SwapFacility.swap
     * @dev Converts seeds to valid addresses and clamped amounts
     */
    function sf_swapPreconditions(
        uint256 tokenInSeed,
        uint256 tokenOutSeed,
        uint256 amountSeed,
        uint256 recipientSeed
    ) internal returns (SF_SwapParams memory params) {
        // Return early if contracts are paused - operations will fail
        if (swapFacility.paused() || jmiExtension.paused()) {
            // Return empty params to signal skip
            return params;
        }

        // Unfreeze currentActor if frozen (frozen accounts cannot transfer)
        if (jmiExtension.isFrozen(currentActor)) {
            vm.prank(freezeManager);
            jmiExtension.unfreeze(currentActor);
        }

        // Valid swap paths:
        // 1. M → Extension (M must be tokenIn)
        // 2. Extension → M (M must be tokenOut)
        // 3. Extension → Extension
        // 4. Asset (USDC/DAI) → JMI Extension

        // Use seed to determine swap path type
        uint256 pathType = tokenInSeed % 4;

        if (pathType == 0) {
            // Path 1: M → Extension
            params.tokenIn = address(mToken);
            if (allExtensions.length > 0) {
                params.tokenOut = allExtensions[tokenOutSeed % allExtensions.length];
            } else {
                params.tokenOut = address(jmiExtension);
            }
        } else if (pathType == 1) {
            // Path 2: Extension → M
            if (allExtensions.length > 0) {
                params.tokenIn = allExtensions[tokenInSeed % allExtensions.length];
            } else {
                params.tokenIn = address(jmiExtension);
            }
            params.tokenOut = address(mToken);
        } else if (pathType == 2) {
            // Path 3: Extension → Extension
            if (allExtensions.length > 0) {
                params.tokenIn = allExtensions[tokenInSeed % allExtensions.length];
                params.tokenOut = allExtensions[tokenOutSeed % allExtensions.length];
                // If same extension, pick different one
                if (params.tokenIn == params.tokenOut && allExtensions.length > 1) {
                    params.tokenOut = allExtensions[(tokenOutSeed + 1) % allExtensions.length];
                }
            } else {
                params.tokenIn = address(jmiExtension);
                params.tokenOut = address(jmiExtension);
            }
        } else {
            // Path 4: Asset (USDC/DAI) → JMI Extension
            // Select DAI or USDC as asset
            if (tokenInSeed % 2 == 0) {
                params.tokenIn = address(DAI);
            } else {
                params.tokenIn = address(USDC);
            }
            params.tokenOut = address(jmiExtension);
        }

        // For Extension → Extension swaps (pathType 2), both must be NON-permissioned
        // This matches the reference's approach in sf_replaceAssetWithMPreconditions
        if (pathType == 2) {
            // Set both extensions as admin-approved but NOT permissioned
            registrar.setEarner(params.tokenIn, true);
            registrar.setEarner(params.tokenOut, true);
            vm.prank(admin);
            swapFacility.setAdminApprovedExtension(params.tokenIn, true);
            vm.prank(admin);
            swapFacility.setPermissionedExtension(params.tokenIn, false);
            vm.prank(admin);
            swapFacility.setAdminApprovedExtension(params.tokenOut, true);
            vm.prank(admin);
            swapFacility.setPermissionedExtension(params.tokenOut, false);
        }

        // Ensure tokenOut extension is approved if needed (for non Extension→Extension paths)
        if (pathType != 2 && params.tokenOut == address(jmiExtension)) {
            // Re-add extension to registrar if removed
            registrar.setEarner(address(jmiExtension), true);

            // Always re-approve to ensure state is correct
            vm.prank(admin);
            swapFacility.setAdminApprovedExtension(address(jmiExtension), true);
            vm.prank(admin);
            swapFacility.setPermissionedExtension(address(jmiExtension), true);
            vm.prank(admin);
            swapFacility.setPermissionedMSwapper(address(jmiExtension), currentActor, true);

            // Ensure tokenIn has a valid asset cap if it's an asset (not M token or extension)
            if (params.tokenIn != address(mToken) && params.tokenIn != address(jmiExtension)) {
                // Check if asset cap is 0 and set it if needed
                uint256 currentCap = jmiExtension.assetCap(params.tokenIn);
                if (currentCap == 0) {
                    vm.prank(assetCapManager);
                    // Set appropriate cap based on decimals
                    if (params.tokenIn == address(DAI)) {
                        jmiExtension.setAssetCap(params.tokenIn, 1_000_000_000e18);
                    } else {
                        jmiExtension.setAssetCap(params.tokenIn, 1_000_000_000e6);
                    }
                }
            }
        }

        // Clamp amount to reasonable range based on token decimals
        // For 18-decimal tokens (DAI), minimum must be 1e12 to not truncate to 0 when converted to 6 decimals
        // For 6-decimal tokens (M, USDC), minimum is 1
        uint256 minAmount = 1;
        uint256 maxAmount = 1_000_000e6; // Default max for 6-decimal tokens (M, USDC)
        if (params.tokenIn == address(DAI)) {
            minAmount = 1e12; // Minimum to produce non-zero JMI amount after decimal conversion
            maxAmount = 1_000_000e18; // Max for 18-decimal tokens
        }
        params.amount = fl.clamp(amountSeed, minAmount, maxAmount);

        // For Extension → M or Extension → Extension, clamp to available M backing
        // Use 99% of backing to avoid edge cases with yield accrual
        if (pathType == 1 || pathType == 2) {
            uint256 mBacking = (mToken.balanceOf(params.tokenIn) * 99) / 100;
            if (params.amount > mBacking) {
                params.amount = mBacking;
            }
            if (params.amount == 0) {
                return params; // Skip if no M backing available
            }
        }

        // Select recipient from USERS
        params.recipient = USERS[recipientSeed % USERS.length];

        // Unfreeze recipient if frozen (frozen accounts cannot receive tokens)
        if (jmiExtension.isFrozen(params.recipient)) {
            vm.prank(freezeManager);
            jmiExtension.unfreeze(params.recipient);
        }
    }

    /**
     * @notice Preconditions for SwapFacility.replaceAssetWithM
     * @dev Converts seeds to valid addresses and clamped amounts
     */
    function sf_replaceAssetWithMPreconditions(
        uint256 assetSeed,
        uint256 extensionInSeed,
        uint256 extensionOutSeed,
        uint256 amountSeed,
        uint256 recipientSeed
    ) internal returns (SF_ReplaceAssetWithMParams memory params) {
        // Return early if contracts are paused - operations will fail
        if (swapFacility.paused() || jmiExtension.paused()) {
            return params;
        }

        // Unfreeze currentActor if frozen (frozen accounts cannot transfer)
        if (jmiExtension.isFrozen(currentActor)) {
            vm.prank(freezeManager);
            jmiExtension.unfreeze(currentActor);
        }

        // Select asset (DAI or USDC)
        if (assetSeed % 2 == 0) {
            params.asset = address(DAI);
        } else {
            params.asset = address(USDC);
        }

        // Select extensionIn from allExtensions
        if (allExtensions.length > 0) {
            params.extensionIn = allExtensions[extensionInSeed % allExtensions.length];
        } else {
            params.extensionIn = address(jmiExtension);
        }

        // Select extensionOut (must be JMI extension)
        params.extensionOut = address(jmiExtension);

        // Re-add both extensions to registrar if removed
        registrar.setEarner(params.extensionIn, true);
        registrar.setEarner(address(jmiExtension), true);

        // For replaceAssetWithM, extensions must NOT be permissioned
        // Set admin approved but permissioned to FALSE
        vm.prank(admin);
        swapFacility.setAdminApprovedExtension(params.extensionIn, true);
        vm.prank(admin);
        swapFacility.setPermissionedExtension(params.extensionIn, false);
        vm.prank(admin);
        swapFacility.setAdminApprovedExtension(address(jmiExtension), true);
        vm.prank(admin);
        swapFacility.setPermissionedExtension(address(jmiExtension), false);

        // Clamp amount to reasonable range (1 to 1M tokens, considering 18 decimals)
        params.amount = fl.clamp(amountSeed, 1, 1_000_000e18);

        // Clamp to available M backing in extensionIn
        // Use 99% of backing to avoid edge cases with yield accrual
        uint256 mBacking = (mToken.balanceOf(params.extensionIn) * 99) / 100;
        if (params.amount > mBacking) {
            params.amount = mBacking;
        }
        if (params.amount == 0) {
            return params; // Skip if no M backing available
        }

        // Select recipient from USERS
        params.recipient = USERS[recipientSeed % USERS.length];

        // Unfreeze recipient if frozen (frozen accounts cannot receive tokens)
        if (jmiExtension.isFrozen(params.recipient)) {
            vm.prank(freezeManager);
            jmiExtension.unfreeze(params.recipient);
        }
    }

    /**
     * @notice Preconditions for SwapFacility.setPermissionedExtension
     * @dev Converts seeds to valid addresses
     */
    function sf_setPermissionedExtensionPreconditions(
        uint256 extensionSeed,
        uint256 permissionedSeed
    ) internal returns (SF_SetPermissionedExtensionParams memory params) {
        // Select extension from allExtensions
        if (allExtensions.length > 0) {
            params.extension = allExtensions[extensionSeed % allExtensions.length];
        } else {
            params.extension = address(jmiExtension);
        }

        params.permissionedSeed = permissionedSeed; // Will be converted to bool in handler
    }

    /**
     * @notice Preconditions for SwapFacility.setPermissionedMSwapper
     * @dev Converts seeds to valid addresses
     */
    function sf_setPermissionedMSwapperPreconditions(
        uint256 extensionSeed,
        uint256 swapperSeed,
        uint256 allowedSeed
    ) internal returns (SF_SetPermissionedMSwapperParams memory params) {
        // Select extension from allExtensions
        if (allExtensions.length > 0) {
            params.extension = allExtensions[extensionSeed % allExtensions.length];
        } else {
            params.extension = address(jmiExtension);
        }

        // Select swapper from USERS
        params.swapper = USERS[swapperSeed % USERS.length];

        params.allowedSeed = allowedSeed; // Will be converted to bool in handler
    }

    /**
     * @notice Preconditions for SwapFacility.setAdminApprovedExtension
     * @dev Converts seeds to valid addresses
     */
    function sf_setAdminApprovedExtensionPreconditions(
        uint256 extensionSeed,
        uint256 approvedSeed
    ) internal returns (SF_SetAdminApprovedExtensionParams memory params) {
        // Select extension from allExtensions
        if (allExtensions.length > 0) {
            params.extension = allExtensions[extensionSeed % allExtensions.length];
        } else {
            params.extension = address(jmiExtension);
        }

        params.approvedSeed = approvedSeed; // Will be converted to bool in handler
    }
}
