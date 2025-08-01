// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "uniswapv3/v3-periphery/base/PeripheryValidation.sol";

abstract contract PeripheryValidationExtended is PeripheryValidation {
    modifier checkPreviousBlockhash(bytes32 previousBlockhash) {
        require(blockhash(block.number - 1) == previousBlockhash, "Blockhash");
        _;
    }
}
