// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.26;

import { IFreezable } from "./IFreezable.sol";

/**
 * @title  FreezableCore
 * @notice Abstract, access-control-agnostic base for freezable contracts.
 *         Provides the FREEZE_MANAGER_ROLE constant, virtual public API, hooks,
 *         and helper functions. Each concrete variant (upgradeable / non-upgradeable)
 *         inherits from this and supplies its own access-control guard and storage.
 * @author M0 Labs
 */
abstract contract FreezableCore is IFreezable {
    /* ============ Variables ============ */

    /// @inheritdoc IFreezable
    bytes32 public constant FREEZE_MANAGER_ROLE = keccak256("FREEZE_MANAGER_ROLE");

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IFreezable
    function freeze(address account) external virtual;

    /// @inheritdoc IFreezable
    function freezeAccounts(address[] calldata accounts) external virtual;

    /// @inheritdoc IFreezable
    function unfreeze(address account) external virtual;

    /// @inheritdoc IFreezable
    function unfreezeAccounts(address[] calldata accounts) external virtual;

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IFreezable
    function isFrozen(address account) public view virtual returns (bool);

    /* ============ Hooks ============ */

    /**
     * @dev   Hook called before freezing an account.
     * @param account The account to be frozen.
     */
    function _beforeFreeze(address account) internal virtual {}

    /**
     * @dev   Hook called before unfreezing an account.
     * @param account The account to be unfrozen.
     */
    function _beforeUnfreeze(address account) internal virtual {}

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @notice Internal function that reverts if an account is frozen.
     * @param  account The account to check.
     */
    function _revertIfFrozen(address account) internal view virtual;

    /**
     * @notice Internal function that reverts if an account is not frozen.
     * @param  account The account to check.
     */
    function _revertIfNotFrozen(address account) internal view virtual;
}
