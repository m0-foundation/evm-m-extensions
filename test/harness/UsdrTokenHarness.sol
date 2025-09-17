// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UsdrToken } from "../../src/UsdrToken.sol";

contract UsdrTokenHarness is UsdrToken {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) UsdrToken(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager
    ) public override initializer {
        super.initialize(name, symbol, yieldRecipient, admin, freezeManager, yieldRecipientManager);
    }

    function setBalanceOf(address account, uint256 amount) external {
        _getMYieldToOneStorageLocation().balanceOf[account] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        _getMYieldToOneStorageLocation().totalSupply = amount;
    }
}
