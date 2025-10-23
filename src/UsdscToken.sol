// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { MYieldToOne } from "./projects/yieldToOne/MYieldToOne.sol";

contract UsdscToken is MYieldToOne {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken_, address swapFacility_) MYieldToOne(mToken_, swapFacility_) {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient_,
        address admin,
        address freezeManager,
        address yieldRecipientManager
    ) public virtual override initializer {
        __MYieldToOne_init(
            name, // "Startale USD"
            symbol, // "USDSC"
            yieldRecipient_, // Treasury wallet address
            admin, // Admin multisig address
            freezeManager, // Freeze manager address (can be same as admin)
            yieldRecipientManager // Yield recipient manager address
        );
    }
}
