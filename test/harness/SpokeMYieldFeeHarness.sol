// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { SpokeMYieldFee } from "../../src/projects/yieldToAllWithFee/SpokeMYieldFee.sol";

contract SpokeMYieldFeeHarness is SpokeMYieldFee {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address mToken,
        address swapFacility,
        uint16 yieldFeeRate,
        address yieldFeeRecipient,
        address admin,
        address yieldFeeManager,
        address claimRecipientManager,
        address rateOracle
    ) public override initializer {
        super.initialize(
            name,
            symbol,
            mToken,
            swapFacility,
            yieldFeeRate,
            yieldFeeRecipient,
            admin,
            yieldFeeManager,
            claimRecipientManager,
            rateOracle
        );
    }

    function currentBlockTimestamp() external view returns (uint40) {
        return _currentBlockTimestamp();
    }

    function currentEarnerRate() external view returns (uint32) {
        return _currentEarnerRate();
    }
}
