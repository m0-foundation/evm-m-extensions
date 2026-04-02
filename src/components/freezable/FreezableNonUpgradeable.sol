// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.26;

import { AccessControl } from "../../../lib/common/lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

import { IFreezable } from "./IFreezable.sol";
import { FreezableCore } from "./FreezableCore.sol";

/**
 * @title  FreezableNonUpgradeable
 * @notice Non-upgradeable contract that allows for the freezing of accounts.
 * @dev    Uses a plain mapping for storage. Intended for non-proxy contracts
 *         where ERC-7201 namespaced storage is unnecessary.
 * @author M0 Labs
 */
abstract contract FreezableNonUpgradeable is FreezableCore, AccessControl {
    /* ============ Variables ============ */

    /// @dev Whether an account is frozen.
    mapping(address account => bool) private _frozenAccounts;

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IFreezable
    function freeze(address account) external virtual override onlyRole(FREEZE_MANAGER_ROLE) {
        _freeze(account);
    }

    /// @inheritdoc IFreezable
    function freezeAccounts(address[] calldata accounts) external virtual override onlyRole(FREEZE_MANAGER_ROLE) {
        for (uint256 i; i < accounts.length; ++i) {
            _freeze(accounts[i]);
        }
    }

    /// @inheritdoc IFreezable
    function unfreeze(address account) external override onlyRole(FREEZE_MANAGER_ROLE) {
        _unfreeze(account);
    }

    /// @inheritdoc IFreezable
    function unfreezeAccounts(address[] calldata accounts) external override onlyRole(FREEZE_MANAGER_ROLE) {
        for (uint256 i; i < accounts.length; ++i) {
            _unfreeze(accounts[i]);
        }
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IFreezable
    function isFrozen(address account) public view override returns (bool) {
        return _frozenAccounts[account];
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @notice Internal function that freezes an account.
     * @param  account The account to freeze.
     */
    function _freeze(address account) internal {
        if (_frozenAccounts[account]) return;

        _beforeFreeze(account);

        _frozenAccounts[account] = true;

        emit Frozen(account, block.timestamp);
    }

    /**
     * @notice Internal function that unfreezes an account.
     * @param  account The account to unfreeze.
     */
    function _unfreeze(address account) internal {
        if (!_frozenAccounts[account]) return;

        _beforeUnfreeze(account);

        _frozenAccounts[account] = false;

        emit Unfrozen(account, block.timestamp);
    }

    /* ============ Internal View/Pure Functions ============ */

    /// @inheritdoc FreezableCore
    function _revertIfFrozen(address account) internal view override {
        if (_frozenAccounts[account]) revert AccountFrozen(account);
    }

    /// @inheritdoc FreezableCore
    function _revertIfNotFrozen(address account) internal view override {
        if (!_frozenAccounts[account]) revert AccountNotFrozen(account);
    }
}
