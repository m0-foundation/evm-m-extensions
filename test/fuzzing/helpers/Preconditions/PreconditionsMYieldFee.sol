// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

contract PreconditionsMYieldFee is PreconditionsBase {
    function claimYieldForPreconditions(uint256 seed) internal returns (ClaimYieldForParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
        params.account = USERS[seed % USERS.length];
    }

    function claimFeePreconditions(uint256 seed) internal returns (ClaimFeeParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
    }

    function updateIndexPreconditions(uint256 seed) internal returns (UpdateIndexParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
    }

    function setFeeRatePreconditions(uint256 seed) internal returns (SetFeeRateParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
        params.feeRate = uint16(fl.clamp(seed, 0, 10000)); // 0 to 10000 bps (100%)
    }

    function setFeeRecipientPreconditions(uint256 seed) internal returns (SetFeeRecipientParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
        params.feeRecipient = USERS[seed % USERS.length];
    }

    function setClaimRecipientPreconditions(uint256 seed) internal returns (SetClaimRecipientParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
        params.account = USERS[seed % USERS.length];
        params.claimRecipient = USERS[(seed + 1) % USERS.length];
    }

    function approvePreconditions_MYieldFee(uint256 seed) internal returns (ApproveParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
        params.spender = USERS[seed % USERS.length];
        params.amount = seed;
    }

    function transferPreconditions_MYieldFee(uint256 seed) internal returns (TransferParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
        params.to = USERS[seed % USERS.length];
        params.amount = fl.clamp(seed, 0, IERC20(params.instance).balanceOf(currentActor));
    }

    function transferFromPreconditions_MYieldFee(uint256 seed) internal returns (TransferFromParams memory params) {
        params.instance = mYieldFeeArray[seed % mYieldFeeArray.length];
        params.from = USERS[seed % USERS.length];
        params.to = USERS[(seed + 1) % USERS.length];
        params.amount = fl.clamp(seed, 0, IERC20(params.instance).balanceOf(currentActor));
    }

    function enableEarningPreconditions_MYieldFee(uint256 seed) internal returns (address) {
        return mYieldFeeArray[seed % mYieldFeeArray.length];
    }

    function disableEarningPreconditions_MYieldFee(uint256 seed) internal returns (address) {
        return mYieldFeeArray[seed % mYieldFeeArray.length];
    }
}
