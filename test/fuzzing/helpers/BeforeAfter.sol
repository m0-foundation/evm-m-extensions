// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "../FuzzSetup.sol";
import { IMYieldToOne } from "src/projects/yieldToOne/IMYieldToOne.sol";
import { IMYieldFee } from "src/projects/yieldToAllWithFee/interfaces/IMYieldFee.sol";
import { IMEarnerManager } from "src/projects/earnerManager/IMEarnerManager.sol";
import { IERC20 } from "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";
import { IMTokenLike } from "src/interfaces/IMTokenLike.sol";

contract BeforeAfter is FuzzSetup {
    // MYieldToOne parameter structs
    struct ClaimYieldParams {
        address instance;
    }

    struct SetYieldRecipientParams {
        address instance;
        address yieldRecipient;
    }

    struct ApproveParams {
        address instance;
        address spender;
        uint256 amount;
    }

    struct TransferParams {
        address instance;
        address to;
        uint256 amount;
    }

    struct TransferFromParams {
        address instance;
        address from;
        address to;
        uint256 amount;
    }

    struct WrapParams {
        address instance;
        address recipient;
        uint256 amount;
    }

    struct UnwrapParams {
        address instance;
        address recipient;
        uint256 amount;
    }

    // MEarnerManager parameter structs
    struct SetAccountInfoParams {
        address instance;
        address account;
        bool status;
        uint16 feeRate;
    }

    struct SetAccountInfoBatchParams {
        address instance;
        address[] accounts;
        bool[] statuses;
        uint16[] feeRates;
    }

    struct SetFeeRecipientParams {
        address instance;
        address feeRecipient;
    }

    struct ClaimForParams {
        address instance;
        address account;
    }

    // MYieldFee parameter structs
    struct ClaimYieldForParams {
        address instance;
        address account;
    }

    struct ClaimFeeParams {
        address instance;
    }

    struct UpdateIndexParams {
        address instance;
    }

    struct SetFeeRateParams {
        address instance;
        uint16 feeRate;
    }

    struct SetClaimRecipientParams {
        address instance;
        address account;
        address claimRecipient;
    }

    // SwapFacility parameter structs
    struct SwapParams {
        address instance;
        address extensionIn;
        address extensionOut;
        uint256 amount;
        address recipient;
        uint8 swapType;
    }

    struct SwapInMParams {
        address instance;
        address extensionOut;
        uint256 amount;
        address recipient;
    }

    struct SwapOutMParams {
        address instance;
        address extensionIn;
        uint256 amount;
        address recipient;
    }

    struct SwapInMWithPermitVRSParams {
        address instance;
        address extensionOut;
        uint256 amount;
        address recipient;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct SwapInMWithPermitSignatureParams {
        address instance;
        address extensionOut;
        uint256 amount;
        address recipient;
        uint256 deadline;
        bytes signature;
    }

    struct SwapInTokenParams {
        address instance;
        address tokenIn;
        uint256 amountIn;
        address extensionOut;
        uint256 minAmountOut;
        address recipient;
        bytes path;
    }

    struct SwapOutTokenParams {
        address instance;
        address extensionIn;
        uint256 amountIn;
        address tokenOut;
        uint256 minAmountOut;
        address recipient;
        bytes path;
    }

    enum SwapType {
        NA,
        YTO_TO_YTO,
        YTO_TO_YFEE,
        YFEE_TO_YTO,
        YFEE_TO_YFEE,
        MEARN_TO_YTO,
        YTO_TO_MEARN,
        MEARN_TO_YFEE,
        YFEE_TO_MEARN,
        MEARN_TO_MEARN
    }

    mapping(uint8 => State) states;

    struct mYieldToOneStruct {
        uint256 yield;
    }

    struct mYieldFeeStruct {
        uint256 totalAccruedYield;
        uint256 totalAccruedFee;
        uint256 balanceOfM0;
        uint256 principalBalanceOf;
        uint256 projectedTotalSupply;
        uint256 currentIndex;
        uint256 latestIndex;
        uint256 latestRate;
        uint256 feeRate;
    }

    struct mEarnerManagerStruct {
        uint256 mBalanceOf;
        uint256 totalSupply;
        uint256 yield;
        uint256 projectedTotalSupply;
        mapping(address => uint256) accruedYieldOf;
        mapping(address => uint256) accruedFeeOf;
        mapping(address => uint256) accruedYieldAndFeeOf;
    }

    struct State {
        mapping(address => ActorStates) actorStates;
        mapping(address => mYieldToOneStruct) mYieldToOne; // YTO
        mapping(address => mYieldFeeStruct) mYieldFee; // YFEE
        mapping(address => mEarnerManagerStruct) mEarnerManager; // MEARN
        uint256 swapFacilityBalanceOfM0;
    }

    struct ActorStates {
        uint256 mTokenBalance;
        uint256 allMEarnTokens;
        uint256 allYieldFeeTokens;
        uint256 allYieldToOneTokens;
        uint256 totalM0Balance;
        uint256 usdcBalance;
    }

    function _before(address[] memory actors) internal {
        // Reset full state mapping
        // delete states[0]; //use only if needed
        // delete states[1]; //use only if needed
        _setStates(0, USERS);
    }

    function _before() internal {
        // Reset full state mapping
        // delete states[0]; //use only if needed
        // delete states[1]; //use only if needed
        _setStates(0, USERS);
    }

    function _after() internal {
        _setStates(1, USERS);
    }

    function _after(address[] memory actors) internal {
        _setStates(1, USERS);
    }

    function _setStates(uint8 callNum, address[] memory actors) internal {
        _processActors(callNum, actors);
        _updateCommonState(callNum);
    }

    function _processActors(uint8 callNum, address[] memory actors) private {
        for (uint256 i = 0; i < actors.length; i++) {
            _setActorState(callNum, actors[i]);
        }
    }

    function _updateCommonState(uint8 callNum) private {
        // For MYieldToOne, we use the yield()
        // For MYieldFee, we use totalAccruedYield()
        // For EarnerManager, we use mBalanceOf(ext) - totalSupply (edited)
        _updateYieldToOneState(callNum);
        _updateYieldFeeState(callNum);
        _updateEarnerManagerState(callNum);
        _updateSwapFacilityState(callNum);
        _checkPoolState(callNum);
    }

    function _updateYieldToOneState(uint8 callNum) private {
        for (uint256 i = 0; i < mYieldToOneArray.length; i++) {
            address extAddress = mYieldToOneArray[i];
            states[callNum].mYieldToOne[extAddress].yield = IMYieldToOne(extAddress).yield();
        }
    }

    function _updateYieldFeeState(uint8 callNum) private {
        for (uint256 i = 0; i < mYieldFeeArray.length; i++) {
            address extAddress = mYieldFeeArray[i];
            states[callNum].mYieldFee[extAddress].balanceOfM0 = mToken.balanceOf(extAddress);
            states[callNum].mYieldFee[extAddress].principalBalanceOf = mToken.principalBalanceOf(extAddress);
            states[callNum].mYieldFee[extAddress].totalAccruedYield = IMYieldFee(extAddress).totalAccruedYield();
            states[callNum].mYieldFee[extAddress].totalAccruedFee = IMYieldFee(extAddress).totalAccruedFee();
            states[callNum].mYieldFee[extAddress].projectedTotalSupply = IMYieldFee(extAddress).projectedTotalSupply();
            // ==== logical coverage ====
            states[callNum].mYieldFee[extAddress].currentIndex = MYieldFee(extAddress).currentIndex();
            states[callNum].mYieldFee[extAddress].latestIndex = MYieldFee(extAddress).latestIndex();
            states[callNum].mYieldFee[extAddress].latestRate = MYieldFee(extAddress).latestRate();
            states[callNum].mYieldFee[extAddress].totalAccruedFee = MYieldFee(extAddress).totalAccruedFee();
            states[callNum].mYieldFee[extAddress].feeRate = MYieldFee(extAddress).feeRate();
        }
    }

    function _updateEarnerManagerState(uint8 callNum) private {
        for (uint256 i = 0; i < mEarnerManagerArray.length; i++) {
            address extAddress = mEarnerManagerArray[i];
            uint256 mBalance = mToken.balanceOf(extAddress);
            uint256 totalSupply = IERC20(extAddress).totalSupply();
            states[callNum].mEarnerManager[extAddress].mBalanceOf = mBalance;
            states[callNum].mEarnerManager[extAddress].totalSupply = totalSupply;
            states[callNum].mEarnerManager[extAddress].yield = mBalance > totalSupply ? mBalance - totalSupply : 0;
            states[callNum].mEarnerManager[extAddress].projectedTotalSupply = MEarnerManager(extAddress)
                .projectedTotalSupply();
            // ==== logical coverage ====
            for (uint256 j = 0; j < USERS.length; j++) {
                address user = USERS[j];
                uint256 accruedYield = MEarnerManager(extAddress).accruedYieldOf(user);
                uint256 accruedFee = MEarnerManager(extAddress).accruedFeeOf(user);
                (uint256 yieldWithFee, , ) = MEarnerManager(extAddress).accruedYieldAndFeeOf(user);
                states[callNum].mEarnerManager[extAddress].accruedYieldOf[user] = accruedYield;
                states[callNum].mEarnerManager[extAddress].accruedFeeOf[user] = accruedFee;
                states[callNum].mEarnerManager[extAddress].accruedYieldAndFeeOf[user] = yieldWithFee;
            }
        }
    }

    function _updateSwapFacilityState(uint8 callNum) private {
        states[callNum].swapFacilityBalanceOfM0 = mToken.balanceOf(address(swapFacility));
    }

    function _checkPoolState(uint8 callNum) private {
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = usdcMTokenPool.slot0();
        uint128 liquidity = usdcMTokenPool.liquidity();
        console.log("sqrtPriceX96", sqrtPriceX96);
        console.log("tick", tick);
        console.log("pool liquidity", liquidity);
    }

    function _setActorState(uint8 callNum, address actor) internal virtual {
        delete states[callNum].actorStates[actor].mTokenBalance;
        delete states[callNum].actorStates[actor].allMEarnTokens;
        delete states[callNum].actorStates[actor].allYieldFeeTokens;
        delete states[callNum].actorStates[actor].allYieldToOneTokens;
        delete states[callNum].actorStates[actor].totalM0Balance;
        delete states[callNum].actorStates[actor].usdcBalance;

        states[callNum].actorStates[actor].mTokenBalance = mToken.balanceOf(actor);
        states[callNum].actorStates[actor].usdcBalance = USDC.balanceOf(actor);
        for (uint256 i = 0; i < mEarnerManagerArray.length; i++) {
            address extAddress = mEarnerManagerArray[i];
            states[callNum].actorStates[actor].allMEarnTokens += IMTokenLike(extAddress).balanceOf(actor);
        }
        for (uint256 i = 0; i < mYieldFeeArray.length; i++) {
            address extAddress = mYieldFeeArray[i];
            states[callNum].actorStates[actor].allYieldFeeTokens += IMTokenLike(extAddress).balanceOf(actor);
        }
        for (uint256 i = 0; i < mYieldToOneArray.length; i++) {
            address extAddress = mYieldToOneArray[i];
            states[callNum].actorStates[actor].allYieldToOneTokens += IMTokenLike(extAddress).balanceOf(actor);
        }
        states[callNum].actorStates[actor].totalM0Balance =
            states[callNum].actorStates[actor].mTokenBalance +
            states[callNum].actorStates[actor].allMEarnTokens +
            states[callNum].actorStates[actor].allYieldFeeTokens +
            states[callNum].actorStates[actor].allYieldToOneTokens;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
