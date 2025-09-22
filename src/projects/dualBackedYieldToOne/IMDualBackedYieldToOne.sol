// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";

import { IMYieldToOne } from "../yieldToOne/IMYieldToOne.sol";

interface IMDualBackedYieldToOne is IMYieldToOne {
    /* ============ Events ============ */

    /**
     * @notice Emitted when the secondary backing is replaced with M.
     * @param  amount The amount of secondary token replaced.
     */
    event SecondaryBackingReplaced(uint256 amount);

    /**
     * @notice Emitted when a secondary token is wrapped for the extension.
     * @param amount The amount of secondary token wrapped into the extension.
     */
    event SecondaryWrap(uint256 amount);

    /* ============ Custom Errors ============ */

    /// @notice Emitted if unwrap is called but there is not enough M to unwrap with.
    error InsufficientMBacking();

    /// @notice Emitted zero address is passed for collateral manager on initialization
    error ZeroCollateralManager();

    /// @notice Emitted zero address is passed for secondary backer on initialization
    error ZeroSecondaryBacker();

    /* ============ Interactive Functions ============ */

    /// @notice Called from the SwapFacility in order to mint the extension with secondary tokens
    /// @param recipient To whom the tokens will be minted
    /// @param amount The amount of tokens to mint
    function wrapSecondary(address recipient, uint256 amount) external;

    /// @notice Allows the collateral manager to replace secondary backing with M.
    /// @param amount the amount of secondary to take out and replace with same amount of M.
    /// @param recipient To whom the secondary backing will be transferred out.
    function replaceSecondary(address recipient, uint256 amount) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The role that can manage the collateral.
    function COLLATERAL_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The total amount of secondary backing in the extension.
    function secondarySupply() external view returns (uint256);

    /// @notice The IERC20 wrapped address of the secondary backing token.
    function secondaryBacker() external view returns (address);
}
