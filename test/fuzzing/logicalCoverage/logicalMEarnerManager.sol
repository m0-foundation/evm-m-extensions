// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/BeforeAfter.sol";

contract LogicalMEarnerManager is BeforeAfter {
    function logicalMEarnerManager() internal {
        uint256 accuredYield_mEarnerManager0_USER1 = states[1].mEarnerManager[mEarnerManagerArray[0]].accruedYieldOf[
            USERS[0]
        ];
        if (accuredYield_mEarnerManager0_USER1 == 0) {
            fl.log("accuredYield_mEarnerManager0_USER1 is 0");
        }
        if (accuredYield_mEarnerManager0_USER1 > 0 && accuredYield_mEarnerManager0_USER1 <= 1e6) {
            fl.log("accuredYield_mEarnerManager0_USER1 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager0_USER1 > 1e6 && accuredYield_mEarnerManager0_USER1 <= 1e12) {
            fl.log("accuredYield_mEarnerManager0_USER1 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager0_USER1 > 1e12 && accuredYield_mEarnerManager0_USER1 <= 1e18) {
            fl.log("accuredYield_mEarnerManager0_USER1 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager0_USER1 > 1e18 && accuredYield_mEarnerManager0_USER1 <= 1e24) {
            fl.log("accuredYield_mEarnerManager0_USER1 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager0_USER1 > 1e24) {
            fl.log("accuredYield_mEarnerManager0_USER1 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager1_USER1 = states[1].mEarnerManager[mEarnerManagerArray[1]].accruedYieldOf[
            USERS[0]
        ];
        if (accuredYield_mEarnerManager1_USER1 == 0) {
            fl.log("accuredYield_mEarnerManager1_USER1 is 0");
        }
        if (accuredYield_mEarnerManager1_USER1 > 0 && accuredYield_mEarnerManager1_USER1 <= 1e6) {
            fl.log("accuredYield_mEarnerManager1_USER1 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager1_USER1 > 1e6 && accuredYield_mEarnerManager1_USER1 <= 1e12) {
            fl.log("accuredYield_mEarnerManager1_USER1 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager1_USER1 > 1e12 && accuredYield_mEarnerManager1_USER1 <= 1e18) {
            fl.log("accuredYield_mEarnerManager1_USER1 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager1_USER1 > 1e18 && accuredYield_mEarnerManager1_USER1 <= 1e24) {
            fl.log("accuredYield_mEarnerManager1_USER1 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager1_USER1 > 1e24) {
            fl.log("accuredYield_mEarnerManager1_USER1 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager2_USER1 = states[1].mEarnerManager[mEarnerManagerArray[2]].accruedYieldOf[
            USERS[0]
        ];
        if (accuredYield_mEarnerManager2_USER1 == 0) {
            fl.log("accuredYield_mEarnerManager2_USER1 is 0");
        }
        if (accuredYield_mEarnerManager2_USER1 > 0 && accuredYield_mEarnerManager2_USER1 <= 1e6) {
            fl.log("accuredYield_mEarnerManager2_USER1 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager2_USER1 > 1e6 && accuredYield_mEarnerManager2_USER1 <= 1e12) {
            fl.log("accuredYield_mEarnerManager2_USER1 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager2_USER1 > 1e12 && accuredYield_mEarnerManager2_USER1 <= 1e18) {
            fl.log("accuredYield_mEarnerManager2_USER1 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager2_USER1 > 1e18 && accuredYield_mEarnerManager2_USER1 <= 1e24) {
            fl.log("accuredYield_mEarnerManager2_USER1 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager2_USER1 > 1e24) {
            fl.log("accuredYield_mEarnerManager2_USER1 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager0_USER2 = states[1].mEarnerManager[mEarnerManagerArray[0]].accruedYieldOf[
            USERS[1]
        ];
        if (accuredYield_mEarnerManager0_USER2 == 0) {
            fl.log("accuredYield_mEarnerManager0_USER2 is 0");
        }
        if (accuredYield_mEarnerManager0_USER2 > 0 && accuredYield_mEarnerManager0_USER2 <= 1e6) {
            fl.log("accuredYield_mEarnerManager0_USER2 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager0_USER2 > 1e6 && accuredYield_mEarnerManager0_USER2 <= 1e12) {
            fl.log("accuredYield_mEarnerManager0_USER2 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager0_USER2 > 1e12 && accuredYield_mEarnerManager0_USER2 <= 1e18) {
            fl.log("accuredYield_mEarnerManager0_USER2 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager0_USER2 > 1e18 && accuredYield_mEarnerManager0_USER2 <= 1e24) {
            fl.log("accuredYield_mEarnerManager0_USER2 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager0_USER2 > 1e24) {
            fl.log("accuredYield_mEarnerManager0_USER2 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager1_USER2 = states[1].mEarnerManager[mEarnerManagerArray[1]].accruedYieldOf[
            USERS[1]
        ];
        if (accuredYield_mEarnerManager1_USER2 == 0) {
            fl.log("accuredYield_mEarnerManager1_USER2 is 0");
        }
        if (accuredYield_mEarnerManager1_USER2 > 0 && accuredYield_mEarnerManager1_USER2 <= 1e6) {
            fl.log("accuredYield_mEarnerManager1_USER2 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager1_USER2 > 1e6 && accuredYield_mEarnerManager1_USER2 <= 1e12) {
            fl.log("accuredYield_mEarnerManager1_USER2 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager1_USER2 > 1e12 && accuredYield_mEarnerManager1_USER2 <= 1e18) {
            fl.log("accuredYield_mEarnerManager1_USER2 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager1_USER2 > 1e18 && accuredYield_mEarnerManager1_USER2 <= 1e24) {
            fl.log("accuredYield_mEarnerManager1_USER2 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager1_USER2 > 1e24) {
            fl.log("accuredYield_mEarnerManager1_USER2 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager2_USER2 = states[1].mEarnerManager[mEarnerManagerArray[2]].accruedYieldOf[
            USERS[1]
        ];
        if (accuredYield_mEarnerManager2_USER2 == 0) {
            fl.log("accuredYield_mEarnerManager2_USER2 is 0");
        }
        if (accuredYield_mEarnerManager2_USER2 > 0 && accuredYield_mEarnerManager2_USER2 <= 1e6) {
            fl.log("accuredYield_mEarnerManager2_USER2 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager2_USER2 > 1e6 && accuredYield_mEarnerManager2_USER2 <= 1e12) {
            fl.log("accuredYield_mEarnerManager2_USER2 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager2_USER2 > 1e12 && accuredYield_mEarnerManager2_USER2 <= 1e18) {
            fl.log("accuredYield_mEarnerManager2_USER2 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager2_USER2 > 1e18 && accuredYield_mEarnerManager2_USER2 <= 1e24) {
            fl.log("accuredYield_mEarnerManager2_USER2 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager2_USER2 > 1e24) {
            fl.log("accuredYield_mEarnerManager2_USER2 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager0_USER3 = states[1].mEarnerManager[mEarnerManagerArray[0]].accruedYieldOf[
            USERS[2]
        ];
        if (accuredYield_mEarnerManager0_USER3 == 0) {
            fl.log("accuredYield_mEarnerManager0_USER3 is 0");
        }
        if (accuredYield_mEarnerManager0_USER3 > 0 && accuredYield_mEarnerManager0_USER3 <= 1e6) {
            fl.log("accuredYield_mEarnerManager0_USER3 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager0_USER3 > 1e6 && accuredYield_mEarnerManager0_USER3 <= 1e12) {
            fl.log("accuredYield_mEarnerManager0_USER3 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager0_USER3 > 1e12 && accuredYield_mEarnerManager0_USER3 <= 1e18) {
            fl.log("accuredYield_mEarnerManager0_USER3 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager0_USER3 > 1e18 && accuredYield_mEarnerManager0_USER3 <= 1e24) {
            fl.log("accuredYield_mEarnerManager0_USER3 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager0_USER3 > 1e24) {
            fl.log("accuredYield_mEarnerManager0_USER3 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager1_USER3 = states[1].mEarnerManager[mEarnerManagerArray[1]].accruedYieldOf[
            USERS[2]
        ];
        if (accuredYield_mEarnerManager1_USER3 == 0) {
            fl.log("accuredYield_mEarnerManager1_USER3 is 0");
        }
        if (accuredYield_mEarnerManager1_USER3 > 0 && accuredYield_mEarnerManager1_USER3 <= 1e6) {
            fl.log("accuredYield_mEarnerManager1_USER3 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager1_USER3 > 1e6 && accuredYield_mEarnerManager1_USER3 <= 1e12) {
            fl.log("accuredYield_mEarnerManager1_USER3 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager1_USER3 > 1e12 && accuredYield_mEarnerManager1_USER3 <= 1e18) {
            fl.log("accuredYield_mEarnerManager1_USER3 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager1_USER3 > 1e18 && accuredYield_mEarnerManager1_USER3 <= 1e24) {
            fl.log("accuredYield_mEarnerManager1_USER3 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager1_USER3 > 1e24) {
            fl.log("accuredYield_mEarnerManager1_USER3 is greater than 1e24");
        }

        uint256 accuredYield_mEarnerManager2_USER3 = states[1].mEarnerManager[mEarnerManagerArray[2]].accruedYieldOf[
            USERS[2]
        ];
        if (accuredYield_mEarnerManager2_USER3 == 0) {
            fl.log("accuredYield_mEarnerManager2_USER3 is 0");
        }
        if (accuredYield_mEarnerManager2_USER3 > 0 && accuredYield_mEarnerManager2_USER3 <= 1e6) {
            fl.log("accuredYield_mEarnerManager2_USER3 is between 0 and 1e6");
        }
        if (accuredYield_mEarnerManager2_USER3 > 1e6 && accuredYield_mEarnerManager2_USER3 <= 1e12) {
            fl.log("accuredYield_mEarnerManager2_USER3 is between 1e6 and 1e12");
        }
        if (accuredYield_mEarnerManager2_USER3 > 1e12 && accuredYield_mEarnerManager2_USER3 <= 1e18) {
            fl.log("accuredYield_mEarnerManager2_USER3 is between 1e12 and 1e18");
        }
        if (accuredYield_mEarnerManager2_USER3 > 1e18 && accuredYield_mEarnerManager2_USER3 <= 1e24) {
            fl.log("accuredYield_mEarnerManager2_USER3 is between 1e18 and 1e24");
        }
        if (accuredYield_mEarnerManager2_USER3 > 1e24) {
            fl.log("accuredYield_mEarnerManager2_USER3 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager0_USER1 = states[1].mEarnerManager[mEarnerManagerArray[0]].accruedFeeOf[
            USERS[0]
        ];
        if (accruedFeeOf_mEarnerManager0_USER1 == 0) {
            fl.log("accruedFeeOf_mEarnerManager0_USER1 is 0");
        }
        if (accruedFeeOf_mEarnerManager0_USER1 > 0 && accruedFeeOf_mEarnerManager0_USER1 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager0_USER1 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager0_USER1 > 1e6 && accruedFeeOf_mEarnerManager0_USER1 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager0_USER1 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager0_USER1 > 1e12 && accruedFeeOf_mEarnerManager0_USER1 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager0_USER1 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager0_USER1 > 1e18 && accruedFeeOf_mEarnerManager0_USER1 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager0_USER1 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager0_USER1 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager0_USER1 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager1_USER1 = states[1].mEarnerManager[mEarnerManagerArray[1]].accruedFeeOf[
            USERS[0]
        ];
        if (accruedFeeOf_mEarnerManager1_USER1 == 0) {
            fl.log("accruedFeeOf_mEarnerManager1_USER1 is 0");
        }
        if (accruedFeeOf_mEarnerManager1_USER1 > 0 && accruedFeeOf_mEarnerManager1_USER1 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager1_USER1 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager1_USER1 > 1e6 && accruedFeeOf_mEarnerManager1_USER1 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager1_USER1 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager1_USER1 > 1e12 && accruedFeeOf_mEarnerManager1_USER1 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager1_USER1 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager1_USER1 > 1e18 && accruedFeeOf_mEarnerManager1_USER1 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager1_USER1 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager1_USER1 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager1_USER1 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager2_USER1 = states[1].mEarnerManager[mEarnerManagerArray[2]].accruedFeeOf[
            USERS[0]
        ];
        if (accruedFeeOf_mEarnerManager2_USER1 == 0) {
            fl.log("accruedFeeOf_mEarnerManager2_USER1 is 0");
        }
        if (accruedFeeOf_mEarnerManager2_USER1 > 0 && accruedFeeOf_mEarnerManager2_USER1 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager2_USER1 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager2_USER1 > 1e6 && accruedFeeOf_mEarnerManager2_USER1 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager2_USER1 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager2_USER1 > 1e12 && accruedFeeOf_mEarnerManager2_USER1 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager2_USER1 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager2_USER1 > 1e18 && accruedFeeOf_mEarnerManager2_USER1 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager2_USER1 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager2_USER1 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager2_USER1 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager0_USER2 = states[1].mEarnerManager[mEarnerManagerArray[0]].accruedFeeOf[
            USERS[1]
        ];
        if (accruedFeeOf_mEarnerManager0_USER2 == 0) {
            fl.log("accruedFeeOf_mEarnerManager0_USER2 is 0");
        }
        if (accruedFeeOf_mEarnerManager0_USER2 > 0 && accruedFeeOf_mEarnerManager0_USER2 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager0_USER2 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager0_USER2 > 1e6 && accruedFeeOf_mEarnerManager0_USER2 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager0_USER2 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager0_USER2 > 1e12 && accruedFeeOf_mEarnerManager0_USER2 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager0_USER2 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager0_USER2 > 1e18 && accruedFeeOf_mEarnerManager0_USER2 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager0_USER2 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager0_USER2 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager0_USER2 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager1_USER2 = states[1].mEarnerManager[mEarnerManagerArray[1]].accruedFeeOf[
            USERS[1]
        ];
        if (accruedFeeOf_mEarnerManager1_USER2 == 0) {
            fl.log("accruedFeeOf_mEarnerManager1_USER2 is 0");
        }
        if (accruedFeeOf_mEarnerManager1_USER2 > 0 && accruedFeeOf_mEarnerManager1_USER2 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager1_USER2 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager1_USER2 > 1e6 && accruedFeeOf_mEarnerManager1_USER2 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager1_USER2 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager1_USER2 > 1e12 && accruedFeeOf_mEarnerManager1_USER2 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager1_USER2 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager1_USER2 > 1e18 && accruedFeeOf_mEarnerManager1_USER2 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager1_USER2 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager1_USER2 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager1_USER2 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager2_USER2 = states[1].mEarnerManager[mEarnerManagerArray[2]].accruedFeeOf[
            USERS[1]
        ];
        if (accruedFeeOf_mEarnerManager2_USER2 == 0) {
            fl.log("accruedFeeOf_mEarnerManager2_USER2 is 0");
        }
        if (accruedFeeOf_mEarnerManager2_USER2 > 0 && accruedFeeOf_mEarnerManager2_USER2 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager2_USER2 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager2_USER2 > 1e6 && accruedFeeOf_mEarnerManager2_USER2 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager2_USER2 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager2_USER2 > 1e12 && accruedFeeOf_mEarnerManager2_USER2 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager2_USER2 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager2_USER2 > 1e18 && accruedFeeOf_mEarnerManager2_USER2 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager2_USER2 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager2_USER2 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager2_USER2 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager0_USER3 = states[1].mEarnerManager[mEarnerManagerArray[0]].accruedFeeOf[
            USERS[2]
        ];
        if (accruedFeeOf_mEarnerManager0_USER3 == 0) {
            fl.log("accruedFeeOf_mEarnerManager0_USER3 is 0");
        }
        if (accruedFeeOf_mEarnerManager0_USER3 > 0 && accruedFeeOf_mEarnerManager0_USER3 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager0_USER3 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager0_USER3 > 1e6 && accruedFeeOf_mEarnerManager0_USER3 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager0_USER3 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager0_USER3 > 1e12 && accruedFeeOf_mEarnerManager0_USER3 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager0_USER3 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager0_USER3 > 1e18 && accruedFeeOf_mEarnerManager0_USER3 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager0_USER3 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager0_USER3 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager0_USER3 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager1_USER3 = states[1].mEarnerManager[mEarnerManagerArray[1]].accruedFeeOf[
            USERS[2]
        ];
        if (accruedFeeOf_mEarnerManager1_USER3 == 0) {
            fl.log("accruedFeeOf_mEarnerManager1_USER3 is 0");
        }
        if (accruedFeeOf_mEarnerManager1_USER3 > 0 && accruedFeeOf_mEarnerManager1_USER3 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager1_USER3 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager1_USER3 > 1e6 && accruedFeeOf_mEarnerManager1_USER3 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager1_USER3 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager1_USER3 > 1e12 && accruedFeeOf_mEarnerManager1_USER3 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager1_USER3 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager1_USER3 > 1e18 && accruedFeeOf_mEarnerManager1_USER3 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager1_USER3 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager1_USER3 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager1_USER3 is greater than 1e24");
        }

        uint256 accruedFeeOf_mEarnerManager2_USER3 = states[1].mEarnerManager[mEarnerManagerArray[2]].accruedFeeOf[
            USERS[2]
        ];
        if (accruedFeeOf_mEarnerManager2_USER3 == 0) {
            fl.log("accruedFeeOf_mEarnerManager2_USER3 is 0");
        }
        if (accruedFeeOf_mEarnerManager2_USER3 > 0 && accruedFeeOf_mEarnerManager2_USER3 <= 1e6) {
            fl.log("accruedFeeOf_mEarnerManager2_USER3 is between 0 and 1e6");
        }
        if (accruedFeeOf_mEarnerManager2_USER3 > 1e6 && accruedFeeOf_mEarnerManager2_USER3 <= 1e12) {
            fl.log("accruedFeeOf_mEarnerManager2_USER3 is between 1e6 and 1e12");
        }
        if (accruedFeeOf_mEarnerManager2_USER3 > 1e12 && accruedFeeOf_mEarnerManager2_USER3 <= 1e18) {
            fl.log("accruedFeeOf_mEarnerManager2_USER3 is between 1e12 and 1e18");
        }
        if (accruedFeeOf_mEarnerManager2_USER3 > 1e18 && accruedFeeOf_mEarnerManager2_USER3 <= 1e24) {
            fl.log("accruedFeeOf_mEarnerManager2_USER3 is between 1e18 and 1e24");
        }
        if (accruedFeeOf_mEarnerManager2_USER3 > 1e24) {
            fl.log("accruedFeeOf_mEarnerManager2_USER3 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager0_USER1 = states[1]
            .mEarnerManager[mEarnerManagerArray[0]]
            .accruedYieldAndFeeOf[USERS[0]];
        if (accruedYieldAndFeeOf_mEarnerManager0_USER1 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER1 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER1 > 0 && accruedYieldAndFeeOf_mEarnerManager0_USER1 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER1 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER1 > 1e6 && accruedYieldAndFeeOf_mEarnerManager0_USER1 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER1 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER1 > 1e12 && accruedYieldAndFeeOf_mEarnerManager0_USER1 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER1 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER1 > 1e18 && accruedYieldAndFeeOf_mEarnerManager0_USER1 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER1 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER1 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER1 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager1_USER1 = states[1]
            .mEarnerManager[mEarnerManagerArray[1]]
            .accruedYieldAndFeeOf[USERS[0]];
        if (accruedYieldAndFeeOf_mEarnerManager1_USER1 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER1 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER1 > 0 && accruedYieldAndFeeOf_mEarnerManager1_USER1 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER1 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER1 > 1e6 && accruedYieldAndFeeOf_mEarnerManager1_USER1 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER1 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER1 > 1e12 && accruedYieldAndFeeOf_mEarnerManager1_USER1 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER1 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER1 > 1e18 && accruedYieldAndFeeOf_mEarnerManager1_USER1 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER1 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER1 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER1 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager2_USER1 = states[1]
            .mEarnerManager[mEarnerManagerArray[2]]
            .accruedYieldAndFeeOf[USERS[0]];
        if (accruedYieldAndFeeOf_mEarnerManager2_USER1 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER1 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER1 > 0 && accruedYieldAndFeeOf_mEarnerManager2_USER1 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER1 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER1 > 1e6 && accruedYieldAndFeeOf_mEarnerManager2_USER1 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER1 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER1 > 1e12 && accruedYieldAndFeeOf_mEarnerManager2_USER1 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER1 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER1 > 1e18 && accruedYieldAndFeeOf_mEarnerManager2_USER1 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER1 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER1 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER1 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager0_USER2 = states[1]
            .mEarnerManager[mEarnerManagerArray[0]]
            .accruedYieldAndFeeOf[USERS[1]];
        if (accruedYieldAndFeeOf_mEarnerManager0_USER2 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER2 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER2 > 0 && accruedYieldAndFeeOf_mEarnerManager0_USER2 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER2 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER2 > 1e6 && accruedYieldAndFeeOf_mEarnerManager0_USER2 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER2 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER2 > 1e12 && accruedYieldAndFeeOf_mEarnerManager0_USER2 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER2 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER2 > 1e18 && accruedYieldAndFeeOf_mEarnerManager0_USER2 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER2 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER2 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER2 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager1_USER2 = states[1]
            .mEarnerManager[mEarnerManagerArray[1]]
            .accruedYieldAndFeeOf[USERS[1]];
        if (accruedYieldAndFeeOf_mEarnerManager1_USER2 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER2 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER2 > 0 && accruedYieldAndFeeOf_mEarnerManager1_USER2 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER2 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER2 > 1e6 && accruedYieldAndFeeOf_mEarnerManager1_USER2 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER2 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER2 > 1e12 && accruedYieldAndFeeOf_mEarnerManager1_USER2 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER2 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER2 > 1e18 && accruedYieldAndFeeOf_mEarnerManager1_USER2 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER2 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER2 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER2 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager2_USER2 = states[1]
            .mEarnerManager[mEarnerManagerArray[2]]
            .accruedYieldAndFeeOf[USERS[1]];
        if (accruedYieldAndFeeOf_mEarnerManager2_USER2 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER2 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER2 > 0 && accruedYieldAndFeeOf_mEarnerManager2_USER2 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER2 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER2 > 1e6 && accruedYieldAndFeeOf_mEarnerManager2_USER2 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER2 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER2 > 1e12 && accruedYieldAndFeeOf_mEarnerManager2_USER2 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER2 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER2 > 1e18 && accruedYieldAndFeeOf_mEarnerManager2_USER2 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER2 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER2 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER2 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager0_USER3 = states[1]
            .mEarnerManager[mEarnerManagerArray[0]]
            .accruedYieldAndFeeOf[USERS[2]];
        if (accruedYieldAndFeeOf_mEarnerManager0_USER3 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER3 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER3 > 0 && accruedYieldAndFeeOf_mEarnerManager0_USER3 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER3 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER3 > 1e6 && accruedYieldAndFeeOf_mEarnerManager0_USER3 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER3 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER3 > 1e12 && accruedYieldAndFeeOf_mEarnerManager0_USER3 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER3 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER3 > 1e18 && accruedYieldAndFeeOf_mEarnerManager0_USER3 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER3 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager0_USER3 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager0_USER3 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager1_USER3 = states[1]
            .mEarnerManager[mEarnerManagerArray[1]]
            .accruedYieldAndFeeOf[USERS[2]];
        if (accruedYieldAndFeeOf_mEarnerManager1_USER3 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER3 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER3 > 0 && accruedYieldAndFeeOf_mEarnerManager1_USER3 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER3 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER3 > 1e6 && accruedYieldAndFeeOf_mEarnerManager1_USER3 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER3 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER3 > 1e12 && accruedYieldAndFeeOf_mEarnerManager1_USER3 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER3 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER3 > 1e18 && accruedYieldAndFeeOf_mEarnerManager1_USER3 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER3 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager1_USER3 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager1_USER3 is greater than 1e24");
        }

        uint256 accruedYieldAndFeeOf_mEarnerManager2_USER3 = states[1]
            .mEarnerManager[mEarnerManagerArray[2]]
            .accruedYieldAndFeeOf[USERS[2]];
        if (accruedYieldAndFeeOf_mEarnerManager2_USER3 == 0) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER3 is 0");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER3 > 0 && accruedYieldAndFeeOf_mEarnerManager2_USER3 <= 1e6) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER3 is between 0 and 1e6");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER3 > 1e6 && accruedYieldAndFeeOf_mEarnerManager2_USER3 <= 1e12) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER3 is between 1e6 and 1e12");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER3 > 1e12 && accruedYieldAndFeeOf_mEarnerManager2_USER3 <= 1e18) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER3 is between 1e12 and 1e18");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER3 > 1e18 && accruedYieldAndFeeOf_mEarnerManager2_USER3 <= 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER3 is between 1e18 and 1e24");
        }
        if (accruedYieldAndFeeOf_mEarnerManager2_USER3 > 1e24) {
            fl.log("accruedYieldAndFeeOf_mEarnerManager2_USER3 is greater than 1e24");
        }
    }
}
