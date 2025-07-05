// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SampleContract {
    error SampleError(string message);

    struct Struct {
        uint256 sampleInput;
        uint256 sampleInput2;
        uint256 sampleInput3;
    }

    function sampleFunction(uint256 sampleInput) public {
        sampleInput = sampleInput + 1;
    }

    function sampleFailWithRequire() public {
        require(false, "Sample fail with require");
    }

    function sampleFailWithCustomError() public {
        revert SampleError("Sample fail with custom error");
    }

    function sampleFailWithPanic() public {
        uint256 zero = 1 - 1;
        uint256(1) / zero;
    }

    function sampleFailWithAssert() public {
        assert(false);
    }

    function sampleFailReturnEmptyData() public {
        //revert and return nothing
        assembly {
            revert(0, 0)
        }
    }

    function complexFunction(
        uint256 sampleInput,
        uint256 sampleInput2,
        uint256 sampleInput3,
        Struct memory sampleStruct
    ) public {
        sampleStruct.sampleInput = sampleStruct.sampleInput + sampleStruct.sampleInput2 + 1;
    }
}
