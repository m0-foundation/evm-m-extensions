pragma solidity ^0.8.0;

contract PropertiesDescriptions {
    // ==============================================================
    // Global Properties (GLOB)
    // These properties define invariants that must hold true across all market states and operations
    // ==============================================================

    string constant SWAP_01 = "SWAP_01: MYieldToOne yield must not change after swaps between same extension types";
    string constant SWAP_02 = "SWAP_02: MYieldFee yield must not change after swaps between same extension types";
    string constant SWAP_03 = "SWAP_03: MEarnerManager yield must not change after swaps between same extension types";

    string constant MYF_01 =
        "MYF_01: Entire yield the extension itself earned from underlying M0 should be equal to distributed yield to users + fee";
    string constant MYF_02 =
        "MYF_02: MYieldFee extension mToken Balance must be greater or equal than projectedSupply + fee";

    // ==============================================================
    // Invariant Properties (INV)
    // These properties define invariants that must hold true as a sample
    // ==============================================================

    string constant ERR_01 = "ERR_01: Unexpected Error";
}
