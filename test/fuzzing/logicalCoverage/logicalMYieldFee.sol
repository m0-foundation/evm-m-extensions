// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/BeforeAfter.sol";

contract LogicalMYieldFee is BeforeAfter {
    function logicalMYieldFee() internal {
        // currentIndex coverage for mYieldFeeArray[0]
        uint256 currentIndex = states[1].mYieldFee[mYieldFeeArray[0]].currentIndex;
        if (currentIndex == 0) {
            fl.log("MYieldFee[0] currentIndex is 0");
        }
        if (currentIndex > 0 && currentIndex <= 1e6) {
            fl.log("MYieldFee[0] currentIndex is between 0 and 1e6");
        }
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
        if (currentIndex == 0) {
            fl.log("MYieldFee[1] currentIndex is 0");
        }
        if (currentIndex > 0 && currentIndex <= 1e6) {
            fl.log("MYieldFee[1] currentIndex is between 0 and 1e6");
        }
        if (currentIndex > 1e6 && currentIndex <= 1e12) {
            fl.log("MYieldFee[1] currentIndex is between 1e6 and 1e12");
        }
        if (currentIndex > 1e12 && currentIndex <= 1e18) {
            fl.log("MYieldFee[1] currentIndex is between 1e12 and 1e18");
        }
        if (currentIndex > 1e18 && currentIndex <= 1e24) {
            fl.log("MYieldFee[1] currentIndex is between 1e18 and 1e24");
        }
        if (currentIndex > 1e24) {
            fl.log("MYieldFee[1] currentIndex is greater than 1e24");
        }
        // currentIndex coverage for mYieldFeeArray[2]
        currentIndex = states[1].mYieldFee[mYieldFeeArray[2]].currentIndex;
        if (currentIndex == 0) {
            fl.log("MYieldFee[2] currentIndex is 0");
        }
        if (currentIndex > 0 && currentIndex <= 1e6) {
            fl.log("MYieldFee[2] currentIndex is between 0 and 1e6");
        }
        if (currentIndex > 1e6 && currentIndex <= 1e12) {
            fl.log("MYieldFee[2] currentIndex is between 1e6 and 1e12");
        }
        if (currentIndex > 1e12 && currentIndex <= 1e18) {
            fl.log("MYieldFee[2] currentIndex is between 1e12 and 1e18");
        }
        if (currentIndex > 1e18 && currentIndex <= 1e24) {
            fl.log("MYieldFee[2] currentIndex is between 1e18 and 1e24");
        }
        if (currentIndex > 1e24) {
            fl.log("MYieldFee[2] currentIndex is greater than 1e24");
        }

        // earnerRate coverage for mYieldFeeArray[0]
        uint256 earnerRate = states[1].mYieldFee[mYieldFeeArray[0]].earnerRate;
        if (earnerRate == 0) {
            fl.log("MYieldFee[0] earnerRate is 0");
        }
        if (earnerRate > 0 && earnerRate <= 1e6) {
            fl.log("MYieldFee[0] earnerRate is between 0 and 1e6");
        }
        if (earnerRate > 1e6 && earnerRate <= 1e12) {
            fl.log("MYieldFee[0] earnerRate is between 1e6 and 1e12");
        }
        if (earnerRate > 1e12 && earnerRate <= 1e18) {
            fl.log("MYieldFee[0] earnerRate is between 1e12 and 1e18");
        }
        if (earnerRate > 1e18 && earnerRate <= 1e24) {
            fl.log("MYieldFee[0] earnerRate is between 1e18 and 1e24");
        }
        if (earnerRate > 1e24) {
            fl.log("MYieldFee[0] earnerRate is greater than 1e24");
        }
        // earnerRate coverage for mYieldFeeArray[1]
        earnerRate = states[1].mYieldFee[mYieldFeeArray[1]].earnerRate;
        if (earnerRate == 0) {
            fl.log("MYieldFee[1] earnerRate is 0");
        }
        if (earnerRate > 0 && earnerRate <= 1e6) {
            fl.log("MYieldFee[1] earnerRate is between 0 and 1e6");
        }
        if (earnerRate > 1e6 && earnerRate <= 1e12) {
            fl.log("MYieldFee[1] earnerRate is between 1e6 and 1e12");
        }
        if (earnerRate > 1e12 && earnerRate <= 1e18) {
            fl.log("MYieldFee[1] earnerRate is between 1e12 and 1e18");
        }
        if (earnerRate > 1e18 && earnerRate <= 1e24) {
            fl.log("MYieldFee[1] earnerRate is between 1e18 and 1e24");
        }
        if (earnerRate > 1e24) {
            fl.log("MYieldFee[1] earnerRate is greater than 1e24");
        }
        // earnerRate coverage for mYieldFeeArray[2]
        earnerRate = states[1].mYieldFee[mYieldFeeArray[2]].earnerRate;
        if (earnerRate == 0) {
            fl.log("MYieldFee[2] earnerRate is 0");
        }
        if (earnerRate > 0 && earnerRate <= 1e6) {
            fl.log("MYieldFee[2] earnerRate is between 0 and 1e6");
        }
        if (earnerRate > 1e6 && earnerRate <= 1e12) {
            fl.log("MYieldFee[2] earnerRate is between 1e6 and 1e12");
        }
        if (earnerRate > 1e12 && earnerRate <= 1e18) {
            fl.log("MYieldFee[2] earnerRate is between 1e12 and 1e18");
        }
        if (earnerRate > 1e18 && earnerRate <= 1e24) {
            fl.log("MYieldFee[2] earnerRate is between 1e18 and 1e24");
        }
        if (earnerRate > 1e24) {
            fl.log("MYieldFee[2] earnerRate is greater than 1e24");
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
        if (latestIndex > 1e18 && latestIndex <= 1e24) {
            fl.log("MYieldFee[0] latestIndex is between 1e18 and 1e24");
        }
        if (latestIndex > 1e24) {
            fl.log("MYieldFee[0] latestIndex is greater than 1e24");
        }
        // latestIndex coverage for mYieldFeeArray[1]
        latestIndex = states[1].mYieldFee[mYieldFeeArray[1]].latestIndex;
        if (latestIndex == 0) {
            fl.log("MYieldFee[1] latestIndex is 0");
        }
        if (latestIndex > 0 && latestIndex <= 1e6) {
            fl.log("MYieldFee[1] latestIndex is between 0 and 1e6");
        }
        if (latestIndex > 1e6 && latestIndex <= 1e12) {
            fl.log("MYieldFee[1] latestIndex is between 1e6 and 1e12");
        }
        if (latestIndex > 1e12 && latestIndex <= 1e18) {
            fl.log("MYieldFee[1] latestIndex is between 1e12 and 1e18");
        }
        if (latestIndex > 1e18 && latestIndex <= 1e24) {
            fl.log("MYieldFee[1] latestIndex is between 1e18 and 1e24");
        }
        if (latestIndex > 1e24) {
            fl.log("MYieldFee[1] latestIndex is greater than 1e24");
        }
        // latestIndex coverage for mYieldFeeArray[2]
        latestIndex = states[1].mYieldFee[mYieldFeeArray[2]].latestIndex;
        if (latestIndex == 0) {
            fl.log("MYieldFee[2] latestIndex is 0");
        }
        if (latestIndex > 0 && latestIndex <= 1e6) {
            fl.log("MYieldFee[2] latestIndex is between 0 and 1e6");
        }
        if (latestIndex > 1e6 && latestIndex <= 1e12) {
            fl.log("MYieldFee[2] latestIndex is between 1e6 and 1e12");
        }
        if (latestIndex > 1e12 && latestIndex <= 1e18) {
            fl.log("MYieldFee[2] latestIndex is between 1e12 and 1e18");
        }
        if (latestIndex > 1e18 && latestIndex <= 1e24) {
            fl.log("MYieldFee[2] latestIndex is between 1e18 and 1e24");
        }
        if (latestIndex > 1e24) {
            fl.log("MYieldFee[2] latestIndex is greater than 1e24");
        }

        // latestRate coverage for mYieldFeeArray[0]
        uint256 latestRate = states[1].mYieldFee[mYieldFeeArray[0]].latestRate;
        if (latestRate == 0) {
            fl.log("MYieldFee[0] latestRate is 0");
        }
        if (latestRate > 0 && latestRate <= 1e6) {
            fl.log("MYieldFee[0] latestRate is between 0 and 1e6");
        }
        if (latestRate > 1e6 && latestRate <= 1e12) {
            fl.log("MYieldFee[0] latestRate is between 1e6 and 1e12");
        }
        if (latestRate > 1e12 && latestRate <= 1e18) {
            fl.log("MYieldFee[0] latestRate is between 1e12 and 1e18");
        }
        if (latestRate > 1e18 && latestRate <= 1e24) {
            fl.log("MYieldFee[0] latestRate is between 1e18 and 1e24");
        }
        if (latestRate > 1e24) {
            fl.log("MYieldFee[0] latestRate is greater than 1e24");
        }
        // latestRate coverage for mYieldFeeArray[1]
        latestRate = states[1].mYieldFee[mYieldFeeArray[1]].latestRate;
        if (latestRate == 0) {
            fl.log("MYieldFee[1] latestRate is 0");
        }
        if (latestRate > 0 && latestRate <= 1e6) {
            fl.log("MYieldFee[1] latestRate is between 0 and 1e6");
        }
        if (latestRate > 1e6 && latestRate <= 1e12) {
            fl.log("MYieldFee[1] latestRate is between 1e6 and 1e12");
        }
        if (latestRate > 1e12 && latestRate <= 1e18) {
            fl.log("MYieldFee[1] latestRate is between 1e12 and 1e18");
        }
        if (latestRate > 1e18 && latestRate <= 1e24) {
            fl.log("MYieldFee[1] latestRate is between 1e18 and 1e24");
        }
        if (latestRate > 1e24) {
            fl.log("MYieldFee[1] latestRate is greater than 1e24");
        }
        // latestRate coverage for mYieldFeeArray[2]
        latestRate = states[1].mYieldFee[mYieldFeeArray[2]].latestRate;
        if (latestRate == 0) {
            fl.log("MYieldFee[2] latestRate is 0");
        }
        if (latestRate > 0 && latestRate <= 1e6) {
            fl.log("MYieldFee[2] latestRate is between 0 and 1e6");
        }
        if (latestRate > 1e6 && latestRate <= 1e12) {
            fl.log("MYieldFee[2] latestRate is between 1e6 and 1e12");
        }
        if (latestRate > 1e12 && latestRate <= 1e18) {
            fl.log("MYieldFee[2] latestRate is between 1e12 and 1e18");
        }
        if (latestRate > 1e18 && latestRate <= 1e24) {
            fl.log("MYieldFee[2] latestRate is between 1e18 and 1e24");
        }
        if (latestRate > 1e24) {
            fl.log("MYieldFee[2] latestRate is greater than 1e24");
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
        if (totalAccruedFee > 1e18 && totalAccruedFee <= 1e24) {
            fl.log("MYieldFee[0] totalAccruedFee is between 1e18 and 1e24");
        }
        if (totalAccruedFee > 1e24) {
            fl.log("MYieldFee[0] totalAccruedFee is greater than 1e24");
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
        if (totalAccruedFee > 1e18 && totalAccruedFee <= 1e24) {
            fl.log("MYieldFee[1] totalAccruedFee is between 1e18 and 1e24");
        }
        if (totalAccruedFee > 1e24) {
            fl.log("MYieldFee[1] totalAccruedFee is greater than 1e24");
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
        if (totalAccruedFee > 1e18 && totalAccruedFee <= 1e24) {
            fl.log("MYieldFee[2] totalAccruedFee is between 1e18 and 1e24");
        }
        if (totalAccruedFee > 1e24) {
            fl.log("MYieldFee[2] totalAccruedFee is greater than 1e24");
        }

        // feeRate coverage for mYieldFeeArray[0]
        uint256 feeRate = states[1].mYieldFee[mYieldFeeArray[0]].feeRate;
        if (feeRate == 0) {
            fl.log("MYieldFee[0] feeRate is 0");
        }
        if (feeRate > 0 && feeRate <= 1e6) {
            fl.log("MYieldFee[0] feeRate is between 0 and 1e6");
        }
        if (feeRate > 1e6 && feeRate <= 1e12) {
            fl.log("MYieldFee[0] feeRate is between 1e6 and 1e12");
        }
        if (feeRate > 1e12 && feeRate <= 1e18) {
            fl.log("MYieldFee[0] feeRate is between 1e12 and 1e18");
        }
        if (feeRate > 1e18 && feeRate <= 1e24) {
            fl.log("MYieldFee[0] feeRate is between 1e18 and 1e24");
        }
        if (feeRate > 1e24) {
            fl.log("MYieldFee[0] feeRate is greater than 1e24");
        }
        // feeRate coverage for mYieldFeeArray[1]
        feeRate = states[1].mYieldFee[mYieldFeeArray[1]].feeRate;
        if (feeRate == 0) {
            fl.log("MYieldFee[1] feeRate is 0");
        }
        if (feeRate > 0 && feeRate <= 1e6) {
            fl.log("MYieldFee[1] feeRate is between 0 and 1e6");
        }
        if (feeRate > 1e6 && feeRate <= 1e12) {
            fl.log("MYieldFee[1] feeRate is between 1e6 and 1e12");
        }
        if (feeRate > 1e12 && feeRate <= 1e18) {
            fl.log("MYieldFee[1] feeRate is between 1e12 and 1e18");
        }
        if (feeRate > 1e18 && feeRate <= 1e24) {
            fl.log("MYieldFee[1] feeRate is between 1e18 and 1e24");
        }
        if (feeRate > 1e24) {
            fl.log("MYieldFee[1] feeRate is greater than 1e24");
        }
        // feeRate coverage for mYieldFeeArray[2]
        feeRate = states[1].mYieldFee[mYieldFeeArray[2]].feeRate;
        if (feeRate == 0) {
            fl.log("MYieldFee[2] feeRate is 0");
        }
        if (feeRate > 0 && feeRate <= 1e6) {
            fl.log("MYieldFee[2] feeRate is between 0 and 1e6");
        }
        if (feeRate > 1e6 && feeRate <= 1e12) {
            fl.log("MYieldFee[2] feeRate is between 1e6 and 1e12");
        }
        if (feeRate > 1e12 && feeRate <= 1e18) {
            fl.log("MYieldFee[2] feeRate is between 1e12 and 1e18");
        }
        if (feeRate > 1e18 && feeRate <= 1e24) {
            fl.log("MYieldFee[2] feeRate is between 1e18 and 1e24");
        }
        if (feeRate > 1e24) {
            fl.log("MYieldFee[2] feeRate is greater than 1e24");
        }
    }
}
