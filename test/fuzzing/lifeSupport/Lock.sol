// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/// @notice A library to implement a reentrancy lock in transient storage.
/// @dev Instead of storing a boolean, the locker's address is stored to allow the contract to know who locked the contract
/// TODO: This library can be deleted when we have the transient keyword support in solidity.
library Locker {
    // The slot holding the locker state, transiently. bytes32(uint256(keccak256("Locker")) - 1)
    bytes32 constant LOCKER_SLOT = 0x0e87e1788ebd9ed6a7e63c70a374cd3283e41cad601d21fbe27863899ed4a708;

    function set(address locker) internal {
        // The locker is always msg.sender or address(0) so does not need to be cleaned
        assembly ("memory-safe") {
            tstore(LOCKER_SLOT, locker)
        }
    }

    function get() internal view returns (address locker) {
        assembly ("memory-safe") {
            locker := tload(LOCKER_SLOT)
        }
    }

    function isLocked() internal view returns (bool) {
        return Locker.get() != address(0);
    }
}

/// @title Lock
/// @notice A contract that provides a reentrancy lock for external calls
contract Lock {
    /// @notice Thrown when attempting to reenter a locked function from an external caller
    error ContractLocked();

    /// @notice Modifier enforcing a reentrancy lock that allows self-reentrancy
    /// @dev If the contract is not locked, use msg.sender as the locker
    modifier isNotLocked() {
        // Apply a reentrancy lock for all external callers
        if (msg.sender != address(this)) {
            if (Locker.isLocked()) revert ContractLocked();
            Locker.set(msg.sender);
            _;
            Locker.set(address(0));
        } else {
            // The contract is allowed to reenter itself, so the lock is not checked
            _;
        }
    }

    /// @notice return the current locker of the contract
    function _getLocker() internal view returns (address) {
        return Locker.get();
    }
}
