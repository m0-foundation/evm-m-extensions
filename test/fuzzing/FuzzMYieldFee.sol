// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/preconditions/PreconditionsMYieldFee.sol";
import "./helpers/postconditions/PostconditionsMYieldFee.sol";

contract FuzzMYieldFee is PreconditionsMYieldFee, PostconditionsMYieldFee {
    function fuzz_claimYieldFor_MYieldFee(uint256 seed) public setCurrentActor {
        ClaimYieldForParams memory params = claimYieldForPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _claimYieldForCall(params.instance, params.account);

        claimYieldForPostconditions(success, returnData);
    }

    function fuzz_claimFee_MYieldFee(uint256 seed) public setCurrentActor {
        ClaimFeeParams memory params = claimFeePreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _claimFeeCall(params.instance);

        claimFeePostconditions(success, returnData);
    }

    function fuzz_updateIndex_MYieldFee(uint256 seed) public setCurrentActor {
        UpdateIndexParams memory params = updateIndexPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _updateIndexCall(params.instance);

        updateIndexPostconditions(success, returnData);
    }

    function fuzz_setFeeRate_MYieldFee(uint256 seed) public setCurrentActor {
        SetFeeRateParams memory params = setFeeRatePreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _setFeeRateCall(params.instance, params.feeRate);

        setFeeRatePostconditions(success, returnData);
    }

    function fuzz_setFeeRecipient_MYieldFee(uint256 seed) public setCurrentActor {
        SetFeeRecipientParams memory params = setFeeRecipientPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _setFeeRecipientCall_MYieldFee(params.instance, params.feeRecipient);

        setFeeRecipientPostconditions_MYieldFee(success, returnData);
    }

    function fuzz_setClaimRecipient_MYieldFee(uint256 seed) public setCurrentActor {
        SetClaimRecipientParams memory params = setClaimRecipientPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _setClaimRecipientCall(
            params.instance,
            params.account,
            params.claimRecipient
        );

        setClaimRecipientPostconditions(success, returnData);
    }

    function fuzz_enableEarning_MYieldFee(uint256 seed) public setCurrentActor {
        address instance = enableEarningPreconditions_MYieldFee(seed);

        _before();

        (bool success, bytes memory returnData) = _enableEarningCall(instance);

        enableEarningPostconditions_MYieldFee(success, returnData);
    }

    function fuzz_disableEarning_MYieldFee(uint256 seed) public setCurrentActor {
        address instance = disableEarningPreconditions_MYieldFee(seed);

        _before();

        (bool success, bytes memory returnData) = _disableEarningCall(instance);

        disableEarningPostconditions_MYieldFee(success, returnData);
    }

    function fuzz_approve_MYieldFee(uint256 seed) public setCurrentActor {
        ApproveParams memory params = approvePreconditions_MYieldFee(seed);

        _before();

        (bool success, bytes memory returnData) = _approveCall(params.instance, params.spender, params.amount);

        approvePostconditions_MYieldFee(success, returnData);
    }

    function fuzz_transfer_MYieldFee(uint256 seed) public setCurrentActor {
        TransferParams memory params = transferPreconditions_MYieldFee(seed);

        _before();

        (bool success, bytes memory returnData) = _transferCall(params.instance, params.to, params.amount);

        transferPostconditions_MYieldFee(success, returnData);
    }

    function fuzz_transferFrom_MYieldFee(uint256 seed) public setCurrentActor {
        TransferFromParams memory params = transferFromPreconditions_MYieldFee(seed);

        _before();

        (bool success, bytes memory returnData) = _transferFromCall(
            params.instance,
            params.from,
            params.to,
            params.amount
        );

        transferFromPostconditions_MYieldFee(success, returnData);
    }
}
