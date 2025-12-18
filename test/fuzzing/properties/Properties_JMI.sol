// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Properties_ERR.sol";

contract Properties_JMI is Properties_ERR {
    function invariant_GLOB_01() internal {
        fl.lte(states[1].jmiTotalAssets, states[1].jmiTotalSupply, GLOB_01);
    }

    // JMI.totalSupply ≤ JMI.totalAssets + M.balanceOf(JMI)
    function invariant_GLOB_02() internal {
        fl.lte(states[1].jmiTotalSupply, states[1].jmiTotalAssets + states[1].jmiMTokenBalance, GLOB_02);
    }
}
