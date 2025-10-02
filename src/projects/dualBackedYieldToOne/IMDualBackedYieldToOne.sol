// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IMYieldToOne } from "../yieldToOne/IMYieldToOne.sol";

interface IMDualBackedYieldToOne is IMYieldToOne {
    /* ============ Events ============ */

    /**
     * @notice Emitted when the secondary token is set.
     * @param  token    Address of the secondary token.
     * @param  decimals Number of decimals used by the secondary token.
     */
    event SecondaryTokenSet(address token, uint8 decimals);

    /**
     * @notice Emitted when the secondary token is swapped for M.
     * @param  token  Address of the secondary token.
     * @param  amount Amount of secondary token swapped.
     */
    event SwappedSecondaryToken(address token, uint256 amount);

    /**
     * @notice Emitted when secondary token is wrapped for the extension.
     * @param  token  Address of the secondary token.
     * @param  amount Amount of secondary token wrapped into the extension.
     */
    event WrappedSecondaryToken(address token, uint256 amount);

    /* ============ Custom Errors ============ */

    /**
     * @notice Emitted if `unwrap()` is called but there is not enough M to unwrap with.
     * @param  amount     Amount of M to unwrap requested.
     * @param  mAvailable Amount of M available.
     */
    error InsufficientMBacking(uint256 amount, uint256 mAvailable);

    /**
     * @notice Emitted if the secondary backing token does not return a decimals value.
     * @param asset Address of the secondary backing token.
     */
    error FailedToGetTokenDecimals(address asset);

    /// @notice Emitted when the secondary token is set to the zero address.
    error ZeroSecondaryToken();

    /* ============ Interactive Functions ============ */

    /*
     * @notice Allows a M holder to swap M for the secondary token.
     * @dev    Only callable by the SwapFacility.
     * @dev    `amount` must be formatted in the secondary token's decimals.
     * @param  amount    Amount of secondary token to swap for M.
     * @param  recipient Address that will receive the secondary token.
     */
    function swapSecondary(address recipient, uint256 amount) external;

    /*
     * @notice Mint extension tokens by depositing secondary token.
     * @dev    Only callable by the SwapFacility.
     * @dev    `amount` must be formatted in the secondary token's decimals.
     * @param  recipient Address that will receive the extension tokens.
     * @param  amount    Amount of tokens to mint.
     */
    function wrapSecondary(address recipient, uint256 amount) external;

    /* ============ View/Pure Functions ============ */

    /// @notice Number of decimals used by the primary backing token (M).
    function M_DECIMALS() external view returns (uint8);

    /// @notice Number of decimals used by the secondary backing token.
    function secondaryDecimals() external view returns (uint8);

    /// @notice Address of the secondary backing token.
    function secondaryToken() external view returns (address);
}
