// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Properties_ERR.sol";

contract Properties_MYF is Properties_ERR {
    //NOTE: invalid
    // function invariant_MYF_01() internal returns (bool) {
    //     for (uint256 i = 0; i < mYieldFeeArray.length; i++) {
    //         address extAddress = mYieldFeeArray[i];
    //         uint256 totalYieldFromM0 = states[1].mYieldFee[extAddress].balanceOfM0 -
    //             states[1].mYieldFee[extAddress].principalBalanceOf;
    //         uint256 reportedYeld = states[1].mYieldFee[extAddress].totalAccruedFee +
    //             states[1].mYieldFee[extAddress].totalAccruedYield;
    //         console.log("totalYieldFromM0", states[1].mYieldFee[extAddress].balanceOfM0); // TODO: del
    //         console.log("principalBalanceOf", states[1].mYieldFee[extAddress].principalBalanceOf);
    //         console.log("totalYieldFromM0", totalYieldFromM0);
    //         console.log("totalAccruedFee", states[1].mYieldFee[extAddress].totalAccruedFee);
    //         console.log("totalAccruedYield", states[1].mYieldFee[extAddress].totalAccruedYield);
    //         console.log("reportedYeld", reportedYeld);
    //         fl.eq(totalYieldFromM0, reportedYeld, MYF_01);
    //     }
    // }

    function invariant_MYF_01() internal returns (bool) {
        for (uint256 i = 0; i < mYieldFeeArray.length; i++) {
            address extAddress = mYieldFeeArray[i];
            fl.gte(
                states[1].mYieldFee[extAddress].balanceOfM0,
                states[1].mYieldFee[extAddress].projectedTotalSupply,
                MYF_01
            );
        }
    }

    function invariant_MYF_02() internal returns (bool) {
        for (uint256 i = 0; i < mYieldFeeArray.length; i++) {
            address extAddress = mYieldFeeArray[i];
            greaterThanOrEqualWithToleranceWei(
                states[1].mYieldFee[extAddress].balanceOfM0,
                states[1].mYieldFee[extAddress].projectedTotalSupply + states[1].mYieldFee[extAddress].totalAccruedFee,
                1,
                MYF_02
            );
        }
    }
}
