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

    /* ============ Custom Errors ============ */

    /// @notice Emitted if no yield is available to claim.
    error NoYield();

    /// @notice Emitted in constructor if Yield Recipient is 0x0.
    error ZeroYieldRecipient();

    /* ============ Interactive Functions ============ */

    /// @notice Claims accrued yield to yield recipient.
    function claimYield() external returns (uint256);

    /* ============ View/Pure Functions ============ */

    /// @notice The address of the M Token contract.
    function yield() external view returns (uint256);

    /// @notice The address of the yield recipient.
    function yieldRecipient() external view returns (address);
}
