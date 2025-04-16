// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

/**
 * @title M Extension where all yield is claimable by a single recipient.
 * @author M^0 Labs
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
     * @param  newRecipient The address of the new yield recipient.
     */
    event YieldRecipientSet(address indexed newRecipient);

    /* ============ Custom Errors ============ */

    /// @notice Emitted if no yield is available to claim.
    error NoYield();

    /// @notice Emitted in constructor if Yield Recipient is 0x0.
    error ZeroYieldRecipient();

    /// @notice Emitted if no recipient manager is set.
    error ZeroYieldRecipientManager();

    /// @notice Emitted if no default admin is set.
    error ZeroDefaultAdmin();

    /* ============ Interactive Functions ============ */

    /// @notice Claims accrued yield to yield recipient.
    function claimYield() external returns (uint256);

    /**
     * @notice Sets the yield recipient.
     * @dev    MUST only be callable by the YIELD_RECIPIENT_MANAGER_ROLE.
     * @dev    SHOULD revert if account is 0x0.
     * @dev    SHOULD return early if the account is already the yield recipient.
     * @param  account The address of the new yield recipient.
     */
    function setYieldRecipient(address account) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The role that can manage the yield recipient.
    function YIELD_RECIPIENT_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The amount of accrued yield.
    function yield() external view returns (uint256);

    /// @notice The address of the yield recipient.
    function yieldRecipient() external view returns (address);
}
