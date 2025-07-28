// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Properties_ERR.sol";

contract Properties_MYF is Properties_ERR {
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
                1000,
                MYF_02
            );
        }
    }
}
