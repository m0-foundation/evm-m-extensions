// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

/**
 * @title Interface for Yield Fee M extension.
 * @author M^0 Labs
 */
interface IMYieldFee {
    /* ============ Events ============ */

    /**
     * @notice Emitted when the last claim index is set for an account.
     * @param  account The address of the account.
     * @param  index   The index that was set.
     */
    event LastClaimIndexSet(address indexed account, uint128 index);

    /**
     * @notice Emitted when the last yield fee claim index is set.
     * @param  index The index that was set.
     */
    event LastYieldFeeClaimIndexSet(uint128 index);

    /**
     * @notice Emitted when an account's yield is claimed.
     * @param  claimer   The address that claimed the yield fee.
     * @param  recipient The address of the recipient.
     * @param  yield     The amount of M yield claimed.
     */
    event YieldClaimed(address indexed claimer, address indexed recipient, uint256 yield);

    /**
     * @notice Emitted when the yield fee is claimed.
     * @param  claimer   The address that claimed the yield fee.
     * @param  recipient The address of the recipient.
     * @param  yieldFee  The amount of yield fee claimed.
     */
    event YieldFeeClaimed(address indexed claimer, address indexed recipient, uint256 yieldFee);

    /**
     * @notice Emitted when yield is claimed for an account and the yield fee is distributed.
     * @param  recipient The address of the recipient.
     * @param  yieldFee  The amount of yield fee distributed and claimable by the recipient.
     */
    event YieldFeeDistributed(address indexed recipient, uint256 yieldFee);

    /* ============ Custom Errors ============ */

    /// @notice Emitted if no yield is available to claim.
    error NoYield();

    /// @notice Emitted in constructor if Yield Recipient is 0x0.
    error ZeroYieldRecipient();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Claims `recipient`'s accrued yield.
     * @dev    Can be used to claim yield on behalf of `recipient`.
     * @param  recipient The address of the recipient.
     */
    function claimYieldFor(address recipient) external returns (uint256);

    /**
     * @notice Claims current accrued yield fee.
     * @dev    Can be used to claim yield fee on behalf of the `yieldFeeRecipient`.
     * @dev    SHOULD return early if the claimable yield fee is zero.
     * @return The amount of yield fee claimed.
     */
    function claimYieldFee() external returns (uint256);

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns the current accrued yield fee.
     * @return The accrued yield fee since the last claim.
     */
    function accruedYieldFee() external returns (uint256);

    /**
     * @notice Returns the yield accrued for `account`, which is claimable.
     * @param  account The account being queried.
     * @return The amount of yield that is claimable.
     */
    function accruedYieldOf(address account) external view returns (uint240);

    /**
     * @notice Returns the token balance of `account` including any accrued yield.
     * @param  account The address of some account.
     * @return The token balance of `account` including any accrued yield.
     */
    function balanceWithYieldOf(address account) external view returns (uint256);

    /**
     * @notice The current index of the Yield Fee extension.
     * @dev SHOULD be virtual to allow other extensions to override it.
     */
    function currentIndex() external view returns (uint128);

    /// @notice The M token's index when earning was most recently enabled.
    function enableMIndex() external view returns (uint128);

    /// @notice The Yield Fee extension index when earning was most recently disabled.
    function disableIndex() external view returns (uint128);

    /// @notice The index at which the yield fee was last claimed.
    function lastYieldFeeClaimIndex() external view returns (uint128);

    /**
     * @notice Returns the principal of `account`.
     * @param  account The address of some account.
     * @return The principal of `account`.
     */
    function principalOf(address account) external view returns (uint112);

    /// @notice The projected total supply if all accrued yield was claimed at this moment.
    function projectedSupply() external view returns (uint240);

    /// @notice The total accrued yield claimable by holders.
    function totalAccruedYield() external view returns (uint240);

    /// @notice The total principal to help compute `totalAccruedYield()`, and thus `excess()`.
    function totalPrincipal() external view returns (uint112);

    /// @notice The yield index of the Yield Fee extension to compute users' yield.
    function yieldIndex() external view returns (uint128);

    /// @notice The yield fee index of the Yield Fee extension to compute cumulative yield fee.
    function yieldFeeIndex() external view returns (uint128);
}
