// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/preconditions/PreconditionsMYieldToOne.sol";
import "./helpers/postconditions/PostconditionsMYieldToOne.sol";

contract FuzzMYieldToOne is PreconditionsMYieldToOne, PostconditionsMYieldToOne {
    function fuzz_claimYield_MYieldToOne(uint256 seed) public setCurrentActor {
        ClaimYieldParams memory params = claimYieldPreconditions(seed);

        _before();

        (bool success, bytes memory returnData) = _claimYieldCall(params.instance);

        claimYieldPostconditions(success, returnData);
    }

    function fuzz_setYieldRecipient_MYieldToOne(uint256 seed) public setCurrentActor {
        SetYieldRecipientParams memory params = setYieldRecipientPreconditions_MYieldToOne(seed);

        _before();

        (bool success, bytes memory returnData) = _setYieldRecipientCall(params.instance, params.yieldRecipient);

        setYieldRecipientPostconditions_MYieldToOne(success, returnData);
    }

    function fuzz_enableEarning_MYieldToOne(uint256 seed) public setCurrentActor {
        address instance = enableEarningPreconditions_MYieldToOne(seed);

        _before();

        (bool success, bytes memory returnData) = _enableEarningCall(instance);

        enableEarningPostconditions_MYieldToOne(success, returnData);
    }

    function fuzz_disableEarning_MYieldToOne(uint256 seed) public setCurrentActor {
        address instance = disableEarningPreconditions_MYieldToOne(seed);

        _before();

        (bool success, bytes memory returnData) = _disableEarningCall(instance);

        disableEarningPostconditions_MYieldToOne(success, returnData);
    }

    function fuzz_approve_MYieldToOne(uint256 seed) public setCurrentActor {
        ApproveParams memory params = approvePreconditions_MYieldToOne(seed);

        _before();

        (bool success, bytes memory returnData) = _approveCall(params.instance, params.spender, params.amount);

        approvePostconditions_MYieldToOne(success, returnData);
    }

    function fuzz_transfer_MYieldToOne(uint256 seed) public setCurrentActor {
        TransferParams memory params = transferPreconditions_MYieldToOne(seed);

        _before();

        (bool success, bytes memory returnData) = _transferCall(params.instance, params.to, params.amount);

        transferPostconditions_MYieldToOne(success, returnData);
    }

    function fuzz_transferFrom_MYieldToOne(uint256 seed) public setCurrentActor {
        TransferFromParams memory params = transferFromPreconditions_MYieldToOne(seed);

        _before();

        (bool success, bytes memory returnData) = _transferFromCall(
            params.instance,
            params.from,
            params.to,
            params.amount
        );

        transferFromPostconditions_MYieldToOne(success, returnData);
    }
}
