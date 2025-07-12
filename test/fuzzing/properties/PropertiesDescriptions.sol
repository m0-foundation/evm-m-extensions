// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PropertiesDescriptions {
    // ==============================================================
    // Global Properties (GLOB)
    // These properties define invariants that must hold true across all market states and operations
    // ==============================================================

    string constant SWAP_01_00 = "SWAP_01 YTO_TO_YTO: MYieldToOne yield must not change after swaps";
    string constant SWAP_01_01 = "SWAP_01 YFEE_TO_YFEE: MYieldFee yield must not change after swaps";
    string constant SWAP_01_02 = "SWAP_01 MEARN_TO_MEARN: MEarnerManager yield must not change after swaps";
    string constant SWAP_02 = "SWAP_02: Swap facility M0 balance must be 0 after swap out";
    string constant SWAP_03 = "SWAP_03: Total M0 balance of all users must not change after swap";
    string constant SWAP_04 = "SWAP_04: Received amount of M0 must be greater or equal than slippage";
    string constant SWAP_05 = "SWAP_05: Received amount of USDC must be greater or equal than slippage";

    // string constant MYF_01 =
    //     "MYF_01: Entire yield the extension itself earned from underlying M0 should be equal to distributed yield to users + fee";
    string constant MYF_01 = "MYF_01: MYieldFee extension mToken Balance must be greater or equal than projectedSupply";
    string constant MYF_02 =
        "MYF_02: MYieldFee extension mToken Balance must be greater or equal than projectedSupply + fee";

    string constant MEARN_01 =
        "MEARN_01: MEarnerManager extension mToken Balance must be greater or equal than projectedTotalSupply";

    // ==============================================================
    // Invariant Properties (INV)
    // These properties define invariants that must hold true as a sample
    // ==============================================================

    string constant ERR_01 = "ERR_01: Unexpected Error";
}
