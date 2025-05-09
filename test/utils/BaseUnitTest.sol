// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { ContinuousIndexingMath } from "../../lib/common/src/libs/ContinuousIndexingMath.sol";
import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";
import { UIntMath } from "../../lib/common/src/libs/UIntMath.sol";

import { MockM } from "../utils/Mocks.sol";

import { Helpers } from "./Helpers.sol";

contract BaseUnitTest is Helpers, Test {
    uint16 public constant YIELD_FEE_RATE = 2000; // 20%

    bytes32 public constant EARNERS_LIST = "earners";
    uint32 public constant M_EARNER_RATE = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY

    uint56 public constant EXP_SCALED_ONE = 1e12;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant YIELD_FEE_MANAGER_ROLE = keccak256("YIELD_FEE_MANAGER_ROLE");
    bytes32 public constant YIELD_RECIPIENT_MANAGER_ROLE = keccak256("YIELD_RECIPIENT_MANAGER_ROLE");

    MockM public mToken;

    uint40 public startTimestamp = 0;
    uint128 public expectedCurrentIndex;
    uint32 public mYiedFeeEarnerRate;

    address public admin = makeAddr("admin");
    address public blacklistManager = makeAddr("blacklistManager");
    address public yieldRecipient = makeAddr("yieldRecipient");
    address public yieldRecipientManager = makeAddr("yieldRecipientManager");
    address public yieldFeeRecipient = makeAddr("yieldFeeRecipient");
    address public yieldFeeManager = makeAddr("yieldFeeManager");

    address public alice;
    uint256 public aliceKey;

    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public charlie = makeAddr("charlie");
    address public david = makeAddr("david");

    address[] public accounts;

    function setUp() public virtual {
        vm.warp(startTimestamp);

        mToken = new MockM();

        mToken.setEarnerRate(M_EARNER_RATE);

        (alice, aliceKey) = makeAddrAndKey("alice");
        accounts = [alice, bob, charlie, david];

        expectedCurrentIndex = 1_100000068703;
        mYiedFeeEarnerRate = _getEarnerRate(M_EARNER_RATE, YIELD_FEE_RATE);
    }

    /* ============ Utils ============ */

    function _getBalanceWithYield(
        uint240 balance,
        uint112 principal,
        uint128 index
    ) internal pure returns (uint240 balanceWithYield_, uint240 yield_) {
        balanceWithYield_ = IndexingMath.getPresentAmountRoundedDown(principal, index);
        yield_ = (balanceWithYield_ <= balance) ? 0 : balanceWithYield_ - balance;
    }

    function _getCurrentIndex(
        uint128 latestIndex,
        uint32 latestRate,
        uint40 latestUpdateTimestamp
    ) internal view returns (uint128) {
        return
            UIntMath.bound128(
                ContinuousIndexingMath.multiplyIndicesDown(
                    latestIndex,
                    ContinuousIndexingMath.getContinuousIndex(
                        ContinuousIndexingMath.convertFromBasisPoints(latestRate),
                        uint32(block.timestamp - latestUpdateTimestamp)
                    )
                )
            );
    }

    function _getMaxAmount(uint128 index) internal pure returns (uint240) {
        return (uint240(type(uint112).max) * index) / EXP_SCALED_ONE;
    }

    /* ============ Fuzz Utils ============ */

    function _getFuzzedBalances(
        uint128 index,
        uint240 balanceWithYield,
        uint240 balance,
        uint240 maxAmount
    ) internal pure returns (uint240, uint240) {
        balanceWithYield = uint240(bound(balanceWithYield, 0, maxAmount));
        balance = uint240(bound(balance, (balanceWithYield * EXP_SCALED_ONE) / index, balanceWithYield));

        return (balanceWithYield, balance);
    }

    function _getFuzzedIndices(
        uint128 currentMIndex_,
        uint128 enableMIndex_,
        uint128 disableIndex_
    ) internal pure returns (uint128, uint128, uint128) {
        currentMIndex_ = uint128(bound(currentMIndex_, EXP_SCALED_ONE, 10 * EXP_SCALED_ONE));
        enableMIndex_ = uint128(bound(enableMIndex_, EXP_SCALED_ONE, currentMIndex_));

        disableIndex_ = uint128(
            bound(disableIndex_, EXP_SCALED_ONE, (currentMIndex_ * EXP_SCALED_ONE) / enableMIndex_)
        );

        return (currentMIndex_, enableMIndex_, disableIndex_);
    }
}
