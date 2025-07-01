// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MSpokeYieldFee } from "../../src/projects/yieldToAllWithFee/MSpokeYieldFee.sol";

contract MSpokeYieldFeeHarness is MSpokeYieldFee {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(MYieldFeeInitParams memory initParams, address rateOracle) public override initializer {
        super.initialize(initParams, rateOracle);
    }

    function currentBlockTimestamp() external view returns (uint40) {
        return _latestEarnerRateAccrualTimestamp();
    }

    function currentEarnerRate() external view returns (uint32) {
        return _currentEarnerRate();
    }
}
