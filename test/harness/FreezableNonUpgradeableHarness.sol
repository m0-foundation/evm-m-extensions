// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { FreezableNonUpgradeable } from "../../src/components/freezable/FreezableNonUpgradeable.sol";

contract FreezableNonUpgradeableHarness is FreezableNonUpgradeable {
    constructor(address freezeManager) {
        _grantRole(FREEZE_MANAGER_ROLE, freezeManager);
    }

    function revertIfFrozen(address account) external view {
        _revertIfFrozen(account);
    }

    function revertIfNotFrozen(address account) external view {
        _revertIfNotFrozen(account);
    }
}
