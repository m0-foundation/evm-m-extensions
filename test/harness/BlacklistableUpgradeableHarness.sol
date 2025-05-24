// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { BlacklistableUpgradeable } from "../../src/abstract/components/BlacklistableUpgradeable.sol";

contract BlacklistableUpgradeableHarness is BlacklistableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address blacklistManager) public initializer {
        __BlacklistableUpgradeable_init(blacklistManager);
    }
}
