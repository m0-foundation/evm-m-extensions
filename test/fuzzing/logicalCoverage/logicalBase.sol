// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./logicalMEarnerManager.sol";
import "./logicalMYieldFee.sol";
import "./logicalMYieldToOne.sol";

contract LogicalBase is LogicalMEarnerManager, LogicalMYieldFee, LogicalMYieldToOne {
    function checkLogicalCoverage() internal {
        logicalMEarnerManager();
        logicalMYieldFee();
        logicalMYieldToOne();
    }
}
