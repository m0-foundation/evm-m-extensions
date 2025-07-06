pragma solidity ^0.8.25;

import "../../properties/Properties.sol";

contract PostconditionsBase is Properties {
    function onSuccessInvariantsGeneral(bytes memory returnData) internal {
        // invariant_MYF_01();
        invariant_MYF_02();
        invariant_SWAP_02();
    }

    function onFailInvariantsGeneral(bytes memory returnData) internal {
        invariant_ERR(returnData);
    }
}
