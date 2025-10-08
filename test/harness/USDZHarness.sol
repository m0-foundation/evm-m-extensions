// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { USDZ } from "../../src/vendor/braid/USDZ.sol";

contract USDZHarness is USDZ {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) USDZ(mToken, swapFacility) {}

    function setBalanceOf(address account, uint256 amount) external {
        _getMYieldToOneStorageLocation().balanceOf[account] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        _getMYieldToOneStorageLocation().totalSupply = amount;
    }
}
