// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { SpokeMYieldFeeUpgradeable } from "../../src/SpokeMYieldFeeUpgradeable.sol";

contract SpokeMYieldFeeUpgradeableHarness is SpokeMYieldFeeUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address mToken,
        uint16 yieldFeeRate,
        address yieldFeeRecipient,
        address admin,
        address yieldFeeManager,
        address rateOracle
    ) public override initializer {
        super.initialize(name, symbol, mToken, yieldFeeRate, yieldFeeRecipient, admin, yieldFeeManager, rateOracle);
    }

    function currentBlockTimestamp() external view returns (uint40) {
        return _currentBlockTimestamp();
    }

    function currentEarnerRate() external view returns (uint32) {
        return _currentEarnerRate();
    }
}
