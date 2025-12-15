// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldToOne } from "../../src/projects/yieldToOne/MYieldToOne.sol";

contract MYieldToOneHarness is MYieldToOne {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MYieldToOne(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address pauser
    ) public override initializer {
        super.initialize(name, symbol, yieldRecipient, admin, freezeManager, yieldRecipientManager, pauser);
    }

    function setBalanceOf(address account, uint256 amount) external {
        _getMYieldToOneStorageLocation().balanceOf[account] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        _getMYieldToOneStorageLocation().totalSupply = amount;
    }
}
