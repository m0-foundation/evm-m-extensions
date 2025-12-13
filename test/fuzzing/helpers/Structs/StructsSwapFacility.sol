// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StructsSwapFacility
 * @notice Struct definitions for SwapFacility fuzz testing
 * @dev These structs are used by both Preconditions and Postconditions
 */

struct SF_SwapParams {
    address tokenIn;
    address tokenOut;
    uint256 amount;
    address recipient;
}

struct SF_ReplaceAssetWithMParams {
    address asset;
    address extensionIn;
    address extensionOut;
    uint256 amount;
    address recipient;
}

struct SF_SetPermissionedExtensionParams {
    address extension;
    uint256 permissionedSeed;
}

struct SF_SetPermissionedMSwapperParams {
    address extension;
    address swapper;
    uint256 allowedSeed;
}

struct SF_SetAdminApprovedExtensionParams {
    address extension;
    uint256 approvedSeed;
}
