// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { SpokeMYieldFee } from "../../src/SpokeMYieldFee.sol";

contract SpokeMYieldFeeHarness is SpokeMYieldFee {
    constructor(
        string memory name,
        string memory symbol,
        address mToken,
        uint16 yieldFeeRate,
        address yieldFeeRecipient,
        address admin,
        address yieldFeeManager,
        address rateOracle
    ) SpokeMYieldFee(name, symbol, mToken, yieldFeeRate, yieldFeeRecipient, admin, yieldFeeManager, rateOracle) {}

    function currentBlockTimestamp() external view returns (uint40) {
        return _currentBlockTimestamp();
    }

    function currentEarnerRate() external view returns (uint32) {
        return _currentEarnerRate();
    }
}
