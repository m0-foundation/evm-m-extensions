pragma solidity ^0.8.0;

contract PropertiesDescriptions {
    // ==============================================================
    // Global Properties (GLOB)
    // These properties define invariants that must hold true across all market states and operations
    // ==============================================================

    string constant SWAP_01 = "SWAP_01: MYieldToOne yield must not change after swaps between same extension types";
    string constant SWAP_02 = "SWAP_02: MYieldFee yield must not change after swaps between same extension types";
    string constant SWAP_03 = "SWAP_03: MEarnerManager yield must not change after swaps between same extension types";

    // ==============================================================
    // Invariant Properties (INV)
    // These properties define invariants that must hold true as a sample
    // ==============================================================

    string constant INV_01 = "INV_01: Sample Invariant";

    string constant ERR_01 = "ERR_01: Unexpected Error";
}
