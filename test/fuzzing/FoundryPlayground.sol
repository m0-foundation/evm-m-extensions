// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FuzzGuided.sol";

contract FoundryPlayground is FuzzGuided {
    function setUp() public {
        vm.warp(1524785992); //echidna starting time
        fuzzSetup();
    }

    function test_basic() public {
        assert(true);
    }

    function test_coverage_mint() public {
        fuzz_randomizeConfigs(1, 0, 0, 0, 0, 0); //1 for default config
        fuzz_mint(2e6);
    }

}
