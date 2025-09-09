// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";

interface IMDualBackedToOne {
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

    /// @notice Emitted in constructor if Yield Recipient is 0x0.
    error ZeroYieldRecipient();

    /// @notice Emitted in constructor if Yield Recipient Manager is 0x0.
    error ZeroYieldRecipientManager();

    /// @notice Emitted in constructor if Admin is 0x0.
    error ZeroAdmin();

    /// @notice Emitted if unwrap is called but there is not enough M to unwrap with.
    error InsufficientMBacking();

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

    /* ============ View/Pure Functions ============ */

    /// @notice The role that can manage the yield recipient.
    function YIELD_RECIPIENT_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The role that can manage the collateral.
    function COLLATERAL_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The amount of accrued yield.
    function yield() external view returns (uint256);

    /// @notice The address of the yield recipient.
    function yieldRecipient() external view returns (address);

    /// @notice The total amount of secondary backing in the extension.
    function secondaryBacking() external view returns (uint256);

    /// @notice The IERC20 wrapped address of the secondary backing token.
    function secondaryBacker() external view returns (IERC20);
}
