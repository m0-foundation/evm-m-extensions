// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PostconditionsBase.sol";

contract PostconditionsMToken is PostconditionsBase {
    function mintPostconditions(address account, uint256 amount) internal {
        _after();
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

    function warpDaysPostconditions() internal {
        _after();
        onSuccessInvariantsGeneral(bytes(""));
    }

    function warpWeeksPostconditions(uint256 weeks_) internal {
        _after();
        onSuccessInvariantsGeneral(bytes(""));
    }
}
