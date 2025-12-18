// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/BeforeAfter.sol";

contract LogicalMYieldToOne is BeforeAfter {
    function logicalMYieldToOne() internal {
        uint256 yield = states[1].mYieldToOne[mYieldToOneArray[0]].yield;
        if (yield == 0) {
            fl.log("MYieldToOne[0] yield is 0");
        }
        if (yield > 0 && yield <= 1e6) {
            fl.log("MYieldToOne[0] yield is between 0 and 1e6");
        }
        if (yield > 1e6 && yield <= 1e12) {
            fl.log("MYieldToOne[0] yield is between 1e6 and 1e12");
        }
        if (yield > 1e12 && yield <= 1e18) {
            fl.log("MYieldToOne[0] yield is between 1e12 and 1e18");
        }

        yield = states[1].mYieldToOne[mYieldToOneArray[1]].yield;
        if (yield == 0) {
            fl.log("MYieldToOne[1] yield is 0");
        }
        if (yield > 0 && yield <= 1e6) {
            fl.log("MYieldToOne[1] yield is between 0 and 1e6");
        }
        if (yield > 1e6 && yield <= 1e12) {
            fl.log("MYieldToOne[1] yield is between 1e6 and 1e12");
        }
        if (yield > 1e12 && yield <= 1e18) {
            fl.log("MYieldToOne[1] yield is between 1e12 and 1e18");
        }

        yield = states[1].mYieldToOne[mYieldToOneArray[2]].yield;
        if (yield == 0) {
            fl.log("MYieldToOne[0] yield is 0");
        }
        if (yield > 0 && yield <= 1e6) {
            fl.log("MYieldToOne[2] yield is between 0 and 1e6");
        }
        if (yield > 1e6 && yield <= 1e12) {
            fl.log("MYieldToOne[2] yield is between 1e6 and 1e12");
        }
        if (yield > 1e12 && yield <= 1e18) {
            fl.log("MYieldToOne[2] yield is between 1e12 and 1e18");
        }
    }
}
