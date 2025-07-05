// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

contract PreconditionsMYieldToOne is PreconditionsBase {
    function claimYieldPreconditions(uint256 seed) internal returns (ClaimYieldParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
    }

    function setYieldRecipientPreconditions_MYieldToOne(
        uint256 seed
    ) internal returns (SetYieldRecipientParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
        params.yieldRecipient = USERS[seed % USERS.length];
    }

    function enableEarningPreconditions_MYieldToOne(uint256 seed) internal returns (EnableEarningParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
    }

    function disableEarningPreconditions_MYieldToOne(
        uint256 seed
    ) internal returns (DisableEarningParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
    }

    function approvePreconditions_MYieldToOne(uint256 seed) internal returns (ApproveParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
        params.spender = USERS[seed % USERS.length];
        params.amount = seed;
    }

    function transferPreconditions_MYieldToOne(uint256 seed) internal returns (TransferParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
        params.to = USERS[seed % USERS.length];
        params.amount = fl.clamp(seed, 0, IERC20(params.instance).balanceOf(currentActor));
    }

    function transferFromPreconditions_MYieldToOne(uint256 seed) internal returns (TransferFromParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
        params.from = USERS[seed % USERS.length];
        params.to = USERS[(seed + 1) % USERS.length];
        params.amount = fl.clamp(seed, 0, IERC20(params.instance).balanceOf(currentActor));
    }

    function wrapPreconditions_MYieldToOne(uint256 seed) internal returns (WrapParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
        params.recipient = USERS[seed % USERS.length];
        params.amount = fl.clamp(seed, 0, mToken.balanceOf(currentActor));
    }

    function unwrapPreconditions_MYieldToOne(uint256 seed) internal returns (UnwrapParams memory params) {
        params.instance = mYieldToOneArray[seed % mYieldToOneArray.length];
        params.recipient = USERS[seed % USERS.length];
        params.amount = fl.clamp(seed, 0, IERC20(params.instance).balanceOf(currentActor));
    }
}
