// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { AccessControlUpgradeable } from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

import { IForcedTransferable } from "./IForcedTransferable.sol";

/**
 * @title  ForcedTransferable
 * @notice Upgradable contract that provides force transfer functionality.
 * @dev This contract is used to claw back funds from frozen accounts by authorized force transfer managers.
 * @author M0 Labs
 */

abstract contract ForcedTransferable is IForcedTransferable, AccessControlUpgradeable {
    /* ============ Variables ============ */

    /// @inheritdoc IForcedTransferable
    bytes32 public constant FORCED_TRANSFER_MANAGER_ROLE = keccak256("FORCED_TRANSFER_MANAGER_ROLE");

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the contract with the given force transfer manager.
     * @param forcedTransferManager The address of a force transfer manager.
     */
    function __ForcedTransferable_init(address forcedTransferManager) internal onlyInitializing {
        if (forcedTransferManager == address(0)) revert ZeroForcedTransferManager();
        _grantRole(FORCED_TRANSFER_MANAGER_ROLE, forcedTransferManager);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IForcedTransferable
    function forceTransfer(
        address frozenAccount,
        address recipient,
        uint256 amount
    ) external onlyRole(FORCED_TRANSFER_MANAGER_ROLE) {
        _forceTransfer(frozenAccount, recipient, amount);
    }

    /// @inheritdoc IForcedTransferable
    function forceTransfers(
        address[] calldata frozenAccounts,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(FORCED_TRANSFER_MANAGER_ROLE) {
        uint256 len = frozenAccounts.length;
        if (len != recipients.length || len != amounts.length) revert ArrayLengthMismatch();

        for (uint256 i; i < len; ++i) {
            _forceTransfer(frozenAccounts[i], recipients[i], amounts[i]);
        }
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Internal ERC20 force transfer function to seize funds from a frozen account.
     * @param frozenAccount The frozen account from which tokens are seized.
     * @param recipient     The recipient's address.
     * @param amount        The amount to be transferred.
     */
    function _forceTransfer(address frozenAccount, address recipient, uint256 amount) internal virtual {}
}
