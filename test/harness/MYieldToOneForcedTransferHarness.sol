// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldToOneForcedTransfer } from "../../src/projects/yieldToOne/MYieldToOneForcedTransfer.sol";

contract MYieldToOneForcedTransferHarness is MYieldToOneForcedTransfer {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MYieldToOneForcedTransfer(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address yieldRecipientManager,
        address admin,
        address freezeManager,
        address pauser,
        address forcedTransferManager
    ) public override initializer {
        super.initialize(
            name,
            symbol,
            yieldRecipient,
            yieldRecipientManager,
            admin,
            freezeManager,
            pauser,
            forcedTransferManager
        );
    }

    function setBalanceOf(address account, uint256 amount) external {
        _getMYieldToOneStorageLocation().balanceOf[account] = amount;
    }
}
