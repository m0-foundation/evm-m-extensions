// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/BeforeAfter.sol";

contract LogicalMYieldFee is BeforeAfter {
    function logicalMYieldFee() internal {
        // currentIndex coverage for mYieldFeeArray[0]
        uint256 currentIndex = states[1].mYieldFee[mYieldFeeArray[0]].currentIndex;

        if (currentIndex > 1e6 && currentIndex <= 1e12) {
            fl.log("MYieldFee[0] currentIndex is between 1e6 and 1e12");
        }
        if (currentIndex > 1e12 && currentIndex <= 1e18) {
            fl.log("MYieldFee[0] currentIndex is between 1e12 and 1e18");
        }
        if (currentIndex > 1e18 && currentIndex <= 1e24) {
            fl.log("MYieldFee[0] currentIndex is between 1e18 and 1e24");
        }
        if (currentIndex > 1e24) {
            fl.log("MYieldFee[0] currentIndex is greater than 1e24");
        }
        // currentIndex coverage for mYieldFeeArray[1]
        currentIndex = states[1].mYieldFee[mYieldFeeArray[1]].currentIndex;

        if (currentIndex > 1e6 && currentIndex <= 1e12) {
            fl.log("MYieldFee[1] currentIndex is between 1e6 and 1e12");
        }
        if (currentIndex > 1e12 && currentIndex <= 1e18) {
            fl.log("MYieldFee[1] currentIndex is between 1e12 and 1e18");
        }

        // currentIndex coverage for mYieldFeeArray[2]
        currentIndex = states[1].mYieldFee[mYieldFeeArray[2]].currentIndex;

        if (currentIndex > 1e6 && currentIndex <= 1e12) {
            fl.log("MYieldFee[2] currentIndex is between 1e6 and 1e12");
        }
        if (currentIndex > 1e12 && currentIndex <= 1e18) {
            fl.log("MYieldFee[2] currentIndex is between 1e12 and 1e18");
        }

        // latestIndex coverage for mYieldFeeArray[0]
        uint256 latestIndex = states[1].mYieldFee[mYieldFeeArray[0]].latestIndex;
        if (latestIndex == 0) {
            fl.log("MYieldFee[0] latestIndex is 0");
        }
        if (latestIndex > 0 && latestIndex <= 1e6) {
            fl.log("MYieldFee[0] latestIndex is between 0 and 1e6");
        }
        if (latestIndex > 1e6 && latestIndex <= 1e12) {
            fl.log("MYieldFee[0] latestIndex is between 1e6 and 1e12");
        }
        if (latestIndex > 1e12 && latestIndex <= 1e18) {
            fl.log("MYieldFee[0] latestIndex is between 1e12 and 1e18");
        }

        // latestIndex coverage for mYieldFeeArray[1]
        latestIndex = states[1].mYieldFee[mYieldFeeArray[1]].latestIndex;

        if (latestIndex > 1e6 && latestIndex <= 1e12) {
            fl.log("MYieldFee[1] latestIndex is between 1e6 and 1e12");
        }
        if (latestIndex > 1e12 && latestIndex <= 1e18) {
            fl.log("MYieldFee[1] latestIndex is between 1e12 and 1e18");
        }

        // latestIndex coverage for mYieldFeeArray[2]
        latestIndex = states[1].mYieldFee[mYieldFeeArray[2]].latestIndex;

        if (latestIndex > 1e6 && latestIndex <= 1e12) {
            fl.log("MYieldFee[2] latestIndex is between 1e6 and 1e12");
        }
        if (latestIndex > 1e12 && latestIndex <= 1e18) {
            fl.log("MYieldFee[2] latestIndex is between 1e12 and 1e18");
        }

        // totalAccruedFee coverage for mYieldFeeArray[0]
        uint256 totalAccruedFee = states[1].mYieldFee[mYieldFeeArray[0]].totalAccruedFee;
        if (totalAccruedFee == 0) {
            fl.log("MYieldFee[0] totalAccruedFee is 0");
        }
        if (totalAccruedFee > 0 && totalAccruedFee <= 1e6) {
            fl.log("MYieldFee[0] totalAccruedFee is between 0 and 1e6");
        }
        if (totalAccruedFee > 1e6 && totalAccruedFee <= 1e12) {
            fl.log("MYieldFee[0] totalAccruedFee is between 1e6 and 1e12");
        }
        if (totalAccruedFee > 1e12 && totalAccruedFee <= 1e18) {
            fl.log("MYieldFee[0] totalAccruedFee is between 1e12 and 1e18");
        }

        // totalAccruedFee coverage for mYieldFeeArray[1]
        totalAccruedFee = states[1].mYieldFee[mYieldFeeArray[1]].totalAccruedFee;
        if (totalAccruedFee == 0) {
            fl.log("MYieldFee[1] totalAccruedFee is 0");
        }
        if (totalAccruedFee > 0 && totalAccruedFee <= 1e6) {
            fl.log("MYieldFee[1] totalAccruedFee is between 0 and 1e6");
        }
        if (totalAccruedFee > 1e6 && totalAccruedFee <= 1e12) {
            fl.log("MYieldFee[1] totalAccruedFee is between 1e6 and 1e12");
        }
        if (totalAccruedFee > 1e12 && totalAccruedFee <= 1e18) {
            fl.log("MYieldFee[1] totalAccruedFee is between 1e12 and 1e18");
        }

        // totalAccruedFee coverage for mYieldFeeArray[2]
        totalAccruedFee = states[1].mYieldFee[mYieldFeeArray[2]].totalAccruedFee;
        if (totalAccruedFee == 0) {
            fl.log("MYieldFee[2] totalAccruedFee is 0");
        }
        if (totalAccruedFee > 0 && totalAccruedFee <= 1e6) {
            fl.log("MYieldFee[2] totalAccruedFee is between 0 and 1e6");
        }
        if (totalAccruedFee > 1e6 && totalAccruedFee <= 1e12) {
            fl.log("MYieldFee[2] totalAccruedFee is between 1e6 and 1e12");
        }
        if (totalAccruedFee > 1e12 && totalAccruedFee <= 1e18) {
            fl.log("MYieldFee[2] totalAccruedFee is between 1e12 and 1e18");
        }
    }
}
