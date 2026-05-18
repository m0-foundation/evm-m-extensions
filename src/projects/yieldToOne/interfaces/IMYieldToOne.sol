// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.26;

/**
 * @title M Extension where all yield is claimable by a single recipient.
 * @author M0 Labs
 */
interface IMYieldToOne {
    /* ============ Events ============ */

    /**
     * @notice Emitted when this contract's excess M is claimed.
     * @param  yield The amount of M yield claimed.
     */
    event YieldClaimed(uint256 yield);

    /**
     * @notice Emitted when the yield recipient is set.
     * @param  yieldRecipient The address of the new yield recipient.
     */
    event YieldRecipientSet(address indexed yieldRecipient);

    /* ============ Custom Errors ============ */

    /// @notice Emitted in initializer if Yield Recipient is 0x0.
    error ZeroYieldRecipient();

    /// @notice Emitted in initializer if Yield Recipient Manager is 0x0.
    error ZeroYieldRecipientManager();

    /// @notice Emitted in initializer if Admin is 0x0.
    error ZeroAdmin();

    /// @notice Emitted when a public read accesses a shielded value without holder authorization
    ///         (caller must use a Seismic signed read with `msg.sender == account`).
    error Unauthorized();

    /// @notice Reverted when the inherited `IERC20.approve` / `permit` path is invoked.
    ///         Callers must use the shielded `approve(address,suint256)` overload.
    error UseShieldedApprove();

    /// @notice Reverted when the inherited `IERC20.transfer` / `transferFrom` path is invoked
    ///         for a non-zero amount. Callers must use the shielded overloads.
    error UseShieldedTransfer();

    /* ============ Interactive Functions ============ */

    /// @notice Claims accrued yield to yield recipient.
    function claimYield() external returns (uint256);

    /**
     * @notice Sets the yield recipient.
     * @dev    MUST only be callable by the YIELD_RECIPIENT_MANAGER_ROLE.
     * @dev    SHOULD revert if `yieldRecipient` is 0x0.
     * @dev    SHOULD return early if the `yieldRecipient` is already the actual yield recipient.
     * @param  yieldRecipient The address of the new yield recipient.
     */
    function setYieldRecipient(address yieldRecipient) external;

    /**
     * @notice Shielded ERC20 transfer. The amount is a Seismic shielded type and is stored
     *         and compared in shielded space; the public `Transfer` event still emits the
     *         cleartext amount for indexer compatibility (events are public on EVM).
     * @param  recipient The address receiving the tokens.
     * @param  amount    The shielded amount to transfer.
     * @return success   Always `true` on non-revert (mirrors `IERC20.transfer`).
     */
    function transfer(address recipient, suint256 amount) external returns (bool);

    /**
     * @notice Shielded ERC20 approve. Stores the allowance as `suint256`.
     * @param  spender The address allowed to spend on behalf of `msg.sender`.
     * @param  amount  The shielded allowance amount. Use `suint256(type(uint256).max)` for an
     *                 infinite, non-decrementing allowance (matches `ERC20ExtendedUpgradeable`).
     * @return success Always `true` on non-revert.
     */
    function approve(address spender, suint256 amount) external returns (bool);

    /**
     * @notice Shielded ERC20 transferFrom. Reads and decrements the shielded allowance in
     *         shielded space. Reverts with `InsufficientAllowance(spender, 0, amount)` —
     *         zeroing the allowance field so the revert payload does not leak the shielded
     *         allowance value.
     * @param  sender    The address whose tokens are being moved.
     * @param  recipient The address receiving the tokens.
     * @param  amount    The shielded amount to transfer.
     * @return success   Always `true` on non-revert.
     */
    function transferFrom(address sender, address recipient, suint256 amount) external returns (bool);

    /* ============ View/Pure Functions ============ */

    /// @notice The role that can manage the yield recipient.
    function YIELD_RECIPIENT_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The amount of accrued yield.
    function yield() external view returns (uint256);

    /// @notice The address of the yield recipient.
    function yieldRecipient() external view returns (address);
}
