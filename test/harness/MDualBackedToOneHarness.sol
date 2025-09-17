// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MDualBackedToOne } from "../../src/projects/dualBackedToOne/MDualBackedToOne.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

contract MDualBackedToOneHarness is MDualBackedToOne {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MDualBackedToOne(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        address secondaryBacker,
        address admin,
        address collateralManager,
        address yieldRecipientManager,
        address yieldRecipient
    ) public override initializer {
        super.initialize(
            name,
            symbol,
            secondaryBacker,
            admin,
            collateralManager,
            yieldRecipientManager,
            yieldRecipient
        );
    }

    function setBalanceOf(address account, uint256 amount) external {
        _getMDualBackedToOneStorageLocation().balanceOf[account] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        _getMDualBackedToOneStorageLocation().totalSupply = amount;
    }

    function setSecondarySupply(uint256 amount) external {
        _getMDualBackedToOneStorageLocation().secondarySupply = amount;
    }
}
