// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.26;

import { AccessControlUpgradeable } from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { IPausable } from "./IPausable.sol";

/**
 * @title Pausable
 * @notice Upgradeable contract that allows to pause the inheriting contract.
 * @dev Relies on PausableUpgradeable from OpenZeppelin for pause functionality.
 * @author M0 Labs
 */
abstract contract Pausable is IPausable, AccessControlUpgradeable, PausableUpgradeable {
    /* ============ Variables ============ */

    /// @inheritdoc IPausable
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the contract with the given pauser.
     * @param pauser The address of a pauser.
     */
    function __Pausable_init(address pauser) internal onlyInitializing {
        if (pauser == address(0)) revert ZeroPauser();
        _grantRole(PAUSER_ROLE, pauser);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IPausable
    function pause() external onlyRole(PAUSER_ROLE) {
        _beforePause();
        _pause();
    }

    /// @inheritdoc IPausable
    function unpause() external onlyRole(PAUSER_ROLE) {
        _beforeUnpause();
        _unpause();
    }

    /* ============ Hooks For Internal Interactive Functions ============ */

    /**
     * @dev   Hook called before pausing the contract.
     */
    function _beforePause() internal virtual {}

    /**
     * @dev    Hook called before unpausing the contract.
     */
    function _beforeUnpause() internal virtual {}
}
