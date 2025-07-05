// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FuzzGuided.sol";

contract FoundryFuzz is FuzzGuided {
    // function setUp() public {
    //     fuzzSetup();
    //     targetContract(address(this));
    //     bytes4[] memory fuzzSelectors = new bytes4[](6);
    //     fuzzSelectors[0] = this.fuzz_sampleFunction.selector;
    //     fuzzSelectors[1] = this.fuzz_sampleFailWithRequire.selector;
    //     fuzzSelectors[2] = this.fuzz_sampleFailWithCustomError.selector;
    //     fuzzSelectors[3] = this.fuzz_sampleFailWithPanic.selector;
    //     fuzzSelectors[4] = this.fuzz_sampleFailWithAssert.selector;
    //     fuzzSelectors[5] = this.fuzz_sampleFailReturnEmptyData.selector;
    //     targetSelector(FuzzSelector({ addr: address(this), selectors: fuzzSelectors }));
    // }
    // function invariant_default() public {
    //     assertTrue(true);
    // }
}
