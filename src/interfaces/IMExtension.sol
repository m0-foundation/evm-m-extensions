// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20Extended } from "../../lib/common/src/interfaces/IERC20Extended.sol";

/**
 * @title  M Extension interface extending Extended ERC20,
 *         includes additional enable/disable earnings and index logic.
 * @author M^0 Labs
 */
interface IMExtension is IERC20Extended {
    /* ============ Events ============ */

    /**
     * @notice Emitted when M extension earning is enabled.
     * @param  index The M index at the moment earning is enabled.
     */
    event EarningEnabled(uint128 index);

    /* ============ Custom Errors ============ */

    /// @notice Emitted when performing an operation that is not allowed when earning is disabled.
    error EarningIsDisabled();

    /// @notice Emitted when performing an operation that is not allowed when earning is enabled.
    error EarningIsEnabled();

    /// @notice Emitted in constructor if M Token is 0x0.
    error ZeroMToken();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Enables earning of extension token if allowed by the TTG Registrar and if it has never been done.
     * @dev SHOULD be virtual to allow extensions to override it.
     */
    function enableEarning() external;

    /**
     * @notice Disables earning of extension token if disallowed by the TTG Registrar and if it has never been done.
     * @dev SHOULD be virtual to allow extensions to override it.
     */
    function disableEarning() external;

    /**
     * @notice Wraps `amount` M from the caller into extension token for `recipient`.
     * @param  recipient The account receiving the minted M extension token.
     * @param  amount    The amount of M extension token minted.
     */
    function wrap(address recipient, uint256 amount) external;

    /**
     * @notice Wraps `amount` M from the caller into extension token for `recipient`, using a permit.
     * @param  recipient The account receiving the minted M extension token.
     * @param  amount    The amount of M deposited.
     * @param  deadline  The last timestamp where the signature is still valid.
     * @param  v         An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  r         An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  s         An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     */
    function wrapWithPermit(
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Wraps `amount` M from the caller into extension token for `recipient`, using a permit.
     * @param  recipient The account receiving the minted M extension token.
     * @param  amount    The amount of M deposited.
     * @param  deadline  The last timestamp where the signature is still valid.
     * @param  signature An arbitrary signature (EIP-712).
     */
    function wrapWithPermit(address recipient, uint256 amount, uint256 deadline, bytes calldata signature) external;

    /**
     * @notice Unwraps `amount` extension token from the caller into M for `recipient`.
     * @param  recipient The account receiving the withdrawn M.
     * @param  amount    The amount of M extension token burned.
     */
    function unwrap(address recipient, uint256 amount) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The address of the M Token contract.
    function mToken() external view returns (address);

    /**
     * @notice Whether M extension earning is enabled.
     * @dev SHOULD be virtual to allow extensions to override it.
     */
    function isEarningEnabled() external view returns (bool);
}
