// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MDualBackedYieldToOne } from "../../src/projects/dualBackedYieldToOne/MDualBackedYieldToOne.sol";

contract MDualBackedYieldToOneHarness is MDualBackedYieldToOne {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MDualBackedYieldToOne(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address secondaryToken
    ) public override initializer {
        super.initialize(name, symbol, yieldRecipient, admin, freezeManager, yieldRecipientManager, secondaryToken);
    }

    function setBalanceOf(address account, uint256 amount) external {
        _getMYieldToOneStorageLocation().balanceOf[account] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        _getMYieldToOneStorageLocation().totalSupply = amount;
    }

    function toExtensionAmount(uint256 amount) external view returns (uint256) {
        return _toExtensionAmount(amount);
    }

    function toSecondaryAmount(uint256 amount) external view returns (uint256) {
        return _toSecondaryAmount(amount);
    }
}
