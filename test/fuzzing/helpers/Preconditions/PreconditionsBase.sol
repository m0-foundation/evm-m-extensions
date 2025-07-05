// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BeforeAfter.sol";

contract PreconditionsBase is BeforeAfter {
    event LogAddress(address actor);

    modifier setCurrentActor() {
        if (_setActor) {
            uint256 fuzzNumber = generateFuzzNumber(iteration, SEED);
            console.log("fuzz iteration", iteration);
            currentActor = USERS[uint256(keccak256(abi.encodePacked(iteration * PRIME + SEED))) % (USERS.length)];

            iteration += 1;

            // vm.startPrank(currentActor);
            console.log("Pranking: ", toString(currentActor)); //echidna logs output
            console.log("Block timestamp: ", block.timestamp);
            //check state and revert workaround
            if (block.timestamp < lastTimestamp) {
                vm.warp(lastTimestamp);
            } else {
                lastTimestamp = block.timestamp;
            }
        }
        emit LogAddress(currentActor);
        _;
        // vm.stopPrank();
        // console.log("Stopped prank: ", toString(msg.sender));
    }

    function setActor(address targetUser) internal {
        address[] memory targetArray = USERS; //use several arrays
        require(targetArray.length > 0, "Target array is empty");

        // Find target user index
        uint256 targetIndex;
        bool found = false;
        for (uint256 i = 0; i < targetArray.length; i++) {
            if (targetArray[i] == targetUser) {
                targetIndex = i;
                console.log("Setting user", targetUser);
                console.log("Index", i);

                found = true;
                break;
            }
        }

        require(found, "Target user not found in array");

        uint256 maxIterations = 100000; //  prevent infinite loops
        uint256 currentIteration = iteration;
        bool iterationFound = false;

        for (uint256 i = 0; i < maxIterations; i++) {
            uint256 hash = uint256(keccak256(abi.encodePacked(currentIteration * PRIME + SEED)));
            uint256 index = hash % targetArray.length;

            if (index == targetIndex) {
                iteration = currentIteration;
                iterationFound = true;
                break;
            }

            currentIteration++;
        }

        require(iterationFound, "User index not found by setter");
    }

    function generateFuzzNumber(uint256 iteration, uint256 seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(iteration * PRIME + seed)));
    }

    function toString(address value) internal pure returns (string memory str) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(value)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
