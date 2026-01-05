// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Properties_ERR.sol";

contract Properties_MEARN is Properties_ERR {
    function invariant_MEARN_01() internal returns (bool) {
        for (uint256 i = 0; i < mEarnerManagerArray.length; i++) {
            address extAddress = mEarnerManagerArray[i];

            greaterThanOrEqualWithToleranceWei(
                states[1].mEarnerManager[extAddress].mBalanceOf,
                states[1].mEarnerManager[extAddress].projectedTotalSupply,
                1,
                MEARN_01
            );
        }
    }
}
