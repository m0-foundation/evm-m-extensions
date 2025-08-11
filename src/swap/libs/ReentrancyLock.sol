// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Locker } from "./Locker.sol";

/**
 * @author Uniswap Labs.
 *         Copied from https://github.com/Uniswap/v4-periphery/blob/main/src/base/ReentrancyLock.sol.
 * @dev    Use Uniswap version of the contract when Linea supports transient storage.
 */
contract ReentrancyLock {
    error ContractLocked();

    modifier isNotLocked() {
        if (Locker.get() != address(0)) revert ContractLocked();
        Locker.set(msg.sender);
        _;
        Locker.set(address(0));
    }

    function _getLocker() internal view returns (address) {
        return Locker.get();
    }
}
