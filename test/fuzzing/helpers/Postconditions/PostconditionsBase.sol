// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "../../properties/Properties.sol";

contract PostconditionsBase is Properties {
    function onSuccessInvariantsGeneral(bytes memory returnData) internal {
        checkLogicalCoverage();

        // invariant_MYF_01();
        invariant_MYF_02();
        invariant_SWAP_02();
        invariant_MEARN_01();
    }

    function onFailInvariantsGeneral(bytes memory returnData) internal {
        checkLogicalCoverage();
        invariant_ERR(returnData);
    }
}
