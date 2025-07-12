// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/preconditions/PreconditionsMEarnerManager.sol";
import "./helpers/postconditions/PostconditionsMEarnerManager.sol";

contract FuzzMEarnerManager is PreconditionsMEarnerManager, PostconditionsMEarnerManager {
    function fuzz_setAccountInfo_MEarnerManager(uint256 seed, bool statusSeed) public setCurrentActor {
        SetAccountInfoParams memory params = setAccountInfoPreconditions(seed, statusSeed);

        _before();

        (bool success, bytes memory returnData) = _setAccountInfoCall(
            params.instance,
            params.account,
            params.status,
            params.feeRate
        );

        setAccountInfoPostconditions(success, returnData);
    }

    function fuzz_setFeeRecipient_MEarnerManager(uint256 seed) public setCurrentActor {
        SetFeeRecipientParams memory params = setFeeRecipientPreconditions_MEarnerManager(seed);

        _before();

        (bool success, bytes memory returnData) = _setFeeRecipientCall(params.instance, params.feeRecipient);

        setFeeRecipientPostconditions_MEarnerManager(success, returnData);
    }

    function fuzz_claimFor_MEarnerManager(uint256 seed) public setCurrentActor {
        ClaimForParams memory params = claimForPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _claimForCall(params.instance, params.account);

        claimForPostconditions(success, returnData);
    }

    function fuzz_approve_MEarnerManager(uint256 seed) public setCurrentActor {
        ApproveParams memory params = approvePreconditions_MEarnerManager(seed);

        _before();

        (bool success, bytes memory returnData) = _approveCall(params.instance, params.spender, params.amount);

        approvePostconditions_MEarnerManager(success, returnData);
    }

    function fuzz_transfer_MEarnerManager(uint256 seed) public setCurrentActor {
        TransferParams memory params = transferPreconditions_MEarnerManager(seed);

        _before();

        (bool success, bytes memory returnData) = _transferCall(params.instance, params.to, params.amount);

        transferPostconditions_MEarnerManager(success, returnData);
    }

    function fuzz_transferFrom_MEarnerManager(uint256 seed) public setCurrentActor {
        TransferFromParams memory params = transferFromPreconditions_MEarnerManager(seed);

        _before();

        (bool success, bytes memory returnData) = _transferFromCall(
            params.instance,
            params.from,
            params.to,
            params.amount
        );

        transferFromPostconditions_MEarnerManager(success, returnData);
    }

    function fuzz_wrap_MEarnerManager(uint256 seed) public setCurrentActor {
        WrapParams memory params = wrapPreconditions_MEarnerManager(seed);

        _before();

        (bool success, bytes memory returnData) = _wrapCall(params.instance, params.recipient, params.amount);

        wrapPostconditions_MEarnerManager(success, returnData);
    }

    function fuzz_unwrap_MEarnerManager(uint256 seed) public setCurrentActor {
        UnwrapParams memory params = unwrapPreconditions_MEarnerManager(seed);

        _before();

        (bool success, bytes memory returnData) = _unwrapCall(params.instance, params.recipient, params.amount);

        unwrapPostconditions_MEarnerManager(success, returnData);
    }

    // function fuzz_enableEarning_MEarnerManager(uint256 seed) public setCurrentActor {
    //     address instance = enableEarningPreconditions_MEarnerManager(seed);

    //     _before();

    //     (bool success, bytes memory returnData) = _enableEarningCall(instance);

    //     enableEarningPostconditions_MEarnerManager(success, returnData);
    // }

    // function fuzz_disableEarning_MEarnerManager(uint256 seed) public setCurrentActor {
    //     address instance = disableEarningPreconditions_MEarnerManager(seed);

    //     _before();

    //     (bool success, bytes memory returnData) = _disableEarningCall(instance);

    //     disableEarningPostconditions_MEarnerManager(success, returnData);
    // }
}
