// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

contract PostconditionsMToken is PostconditionsBase {
    function mintPostconditions(address account, uint256 amount) internal {
        // if (success) {
        _after();
        // onSuccessInvariantsGeneral(bytes(""));
        // } else {
        // onFailInvariantsGeneral(bytes(""));
        // }
    }

    function startEarningPostconditions(bool success, bytes memory returnData, address account) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }

    function stopEarningPostconditions(bool success, bytes memory returnData, address account) internal {
        if (success) {
            _after();
            onSuccessInvariantsGeneral(returnData);
        } else {
            onFailInvariantsGeneral(returnData);
        }
    }
}
