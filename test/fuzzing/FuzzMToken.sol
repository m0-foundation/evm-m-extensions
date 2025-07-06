// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/preconditions/PreconditionsMToken.sol";
import "./helpers/postconditions/PostconditionsMToken.sol";

contract FuzzMToken is PreconditionsMToken, PostconditionsMToken {
    function fuzz_mint(uint256 seed) public setCurrentActor {
        (address account, uint256 amount) = mintPreconditions(seed);

        _before();

        mintMToken(account, amount);

        mintPostconditions(account, amount);
    }

    function fuzz_startEarning() public setCurrentActor {
        _before();

        (bool success, bytes memory returnData) = _startEarningCall(currentActor);

        startEarningPostconditions(success, returnData, currentActor);
    }

    function fuzz_stopEarning() public setCurrentActor {
        _before();

        (bool success, bytes memory returnData) = _stopEarningCall(currentActor);

        stopEarningPostconditions(success, returnData, currentActor);
    }

    function fuzz_warpDays(uint256 days_) public {
        _before();
        days_ = fl.clamp(days_, 1, 365);
        vm.warp(block.timestamp + days_ * 1 days);
        vm.roll(block.number + days_ * 1000);
        warpDaysPostconditions();
    }

    function fuzz_warpWeeks(uint256 weeks_) public {
        _before();
        weeks_ = fl.clamp(weeks_, 1, 10);
        vm.warp(block.timestamp + weeks_ * 1 weeks);
        vm.roll(block.number + weeks_ * 1000);
        warpWeeksPostconditions(weeks_);
    }
}
