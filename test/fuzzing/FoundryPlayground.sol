// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FuzzGuided.sol";

contract FoundryPlayground is FuzzGuided {
    function setUp() public {
        vm.warp(1524785992); //echidna starting time
        fuzzSetup();
    }

    function test_basic() public {
        assert(false);
    }

    function test_coverage_mint() public {
        fuzz_mint(2e6);
        setActor(USER2);
        fuzz_warpWeeks(1);
        setActor(USER2);
        fuzz_swapInM(1e6);
        fuzz_warpDays(1);
        setActor(USER2);
        fuzz_swapOutM(1e6);
    }

    function test_coverage_SwapInToken() public {
        fuzz_mint(2e6);
        setActor(USER2);
        fuzz_warpWeeks(1);
        setActor(USER2);
        fuzz_swapInToken(1e6);
        setActor(USER2);
        fuzz_swapOutToken(1e6);
    }

    function test_swapInToken() public {
        fuzz_swapInToken(1e6);
    }

    function test_setFeeRecipient_MYieldFee() public {
        fuzz_setFeeRecipient_MYieldFee(0);
    }

    function test_setClaimRecipient_MYieldFee() public {
        fuzz_setClaimRecipient_MYieldFee(1243842114999043724632953757827977672887);
    }

    function test_swapOutToken_MEarnerManager() public {
        fuzz_transferFrom_MYieldFee(0);
        fuzz_transferFrom_MYieldFee(3627267021883914267372266916118009144674103721966203995273361491607);
        fuzz_approve_MYieldFee(17746552764780105160738418812046093807414944557038597050867616710064);
        fuzz_approve_MEarnerManager(72511897545339256365686171027320470996271315535875310140166);
        fuzz_setFeeRecipient_MEarnerManager(143763691406449532991508316138316936871138116615149875197084);
        fuzz_transfer_MYieldFee(0);
        fuzz_swapInM(2273847);
        fuzz_swapOutToken(38823);
    }

    function test_swapInToken_MEarnerManager() public {
        fuzz_swapInToken(1);
    }
}
