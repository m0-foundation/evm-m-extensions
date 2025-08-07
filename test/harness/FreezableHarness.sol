// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Freezable } from "../../src/components/Freezable.sol";

contract FreezableHarness is Freezable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address freezelistManager) public initializer {
        __Freezable_init(freezelistManager);
    }
}
