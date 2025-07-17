// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

contract PreconditionsMEarnerManager is PreconditionsBase {
    function setAccountInfoPreconditions(
        uint256 seed,
        bool statusSeed
    ) internal returns (SetAccountInfoParams memory params) {
        if (seed % 2 == 0) {
            params.instance = mEarnerManagerArray[seed % mEarnerManagerArray.length];
            params.account = USERS[seed % USERS.length];
            params.status = (seed % 2) == 1;
        } else {
            params.instance = mEarnerManagerArray[seed % mEarnerManagerArray.length];
            params.account = USERS[seed % USERS.length];
            params.status = statusSeed;
            params.feeRate = uint16(fl.clamp(seed, 0, type(uint16).max)); // 0 to 10000 bps (100%)
        }
    }

    function setFeeRecipientPreconditions_MEarnerManager(
        uint256 seed
    ) internal returns (SetFeeRecipientParams memory params) {
        params.instance = mEarnerManagerArray[seed % mEarnerManagerArray.length];
        params.feeRecipient = USERS[seed % USERS.length];
    }

    function claimForPreconditions(uint256 seed) internal returns (ClaimForParams memory params) {
        params.instance = mEarnerManagerArray[seed % mEarnerManagerArray.length];
        params.account = USERS[seed % USERS.length];
    }

    function approvePreconditions_MEarnerManager(uint256 seed) internal returns (ApproveParams memory params) {
        params.instance = mEarnerManagerArray[seed % mEarnerManagerArray.length];
        params.spender = USERS[seed % USERS.length];
        params.amount = seed;
    }

    function transferPreconditions_MEarnerManager(uint256 seed) internal returns (TransferParams memory params) {
        params.instance = mEarnerManagerArray[seed % mEarnerManagerArray.length];
        params.to = USERS[seed % USERS.length];
        params.amount = fl.clamp(seed, 0, IERC20(params.instance).balanceOf(currentActor));
    }

    function transferFromPreconditions_MEarnerManager(
        uint256 seed
    ) internal returns (TransferFromParams memory params) {
        params.instance = mEarnerManagerArray[seed % mEarnerManagerArray.length];
        params.from = USERS[seed % USERS.length];
        params.to = USERS[(seed + 1) % USERS.length];
        params.amount = fl.clamp(seed, 0, IERC20(params.instance).balanceOf(currentActor));
    }

    function enableEarningPreconditions_MEarnerManager(uint256 seed) internal returns (address) {
        return mEarnerManagerArray[seed % mEarnerManagerArray.length];
    }

    function disableEarningPreconditions_MEarnerManager(uint256 seed) internal returns (address) {
        return mEarnerManagerArray[seed % mEarnerManagerArray.length];
    }
}
