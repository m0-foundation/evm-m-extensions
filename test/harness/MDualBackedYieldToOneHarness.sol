// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MDualBackedYieldToOne } from "../../src/projects/dualBackedYieldToOne/MDualBackedYieldToOne.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

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
        address collateralManager,
        address secondaryBacker
    ) public override initializer {
        super.initialize(
            name,
            symbol,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            collateralManager,
            secondaryBacker
        );
    }

    function setBalanceOf(address account, uint256 amount) external {
        _getMYieldToOneStorageLocation().balanceOf[account] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        _getMYieldToOneStorageLocation().totalSupply = amount;
    }

    function setSecondarySupply(uint256 amount) external {
        _getMDualBackedYieldToOneStorageLocation().secondarySupply = amount;
    }
}
