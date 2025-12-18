// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StructsJMIExtension
 * @notice Struct definitions for JMIExtension fuzz testing
 * @dev These structs are used by both Preconditions and Postconditions
 */

struct JMI_SetAssetCapParams {
    address instance;
    address asset;
    uint256 cap;
}

struct JMI_PauseParams {
    address instance;
}

struct JMI_FreezeParams {
    address instance;
    address account;
}

struct JMI_UnfreezeParams {
    address instance;
    address account;
}
