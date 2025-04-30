// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { ContinuousIndexingMath } from "../../lib/common/src/libs/ContinuousIndexingMath.sol";
import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";
import { UIntMath } from "../../lib/common/src/libs/UIntMath.sol";

import { MockM, MockRateOracle } from "../utils/Mocks.sol";

contract BaseUnitTest is Test {
    uint16 public constant HUNDRED_PERCENT = 10_000;
    uint16 public constant YIELD_FEE_RATE = 2000; // 20%

    bytes32 public constant EARNERS_LIST = "earners";
    uint32 public constant EARNER_RATE = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY

    uint56 public constant EXP_SCALED_ONE = 1e12;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant YIELD_FEE_MANAGER_ROLE = keccak256("YIELD_FEE_MANAGER_ROLE");

    MockM public mToken;
    MockRateOracle public rateOracle;

    uint256 public startTimestamp = vm.getBlockTimestamp();
    uint128 public expectedCurrentIndex;

    address public admin = makeAddr("admin");
    address public blacklistManager = makeAddr("blacklistManager");
    address public yieldRecipient = makeAddr("yieldRecipient");
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
        mToken = new MockM();
        rateOracle = new MockRateOracle();

        rateOracle.setEarnerRate(EARNER_RATE);

        (alice, aliceKey) = makeAddrAndKey("alice");
        accounts = [alice, bob, charlie, david];

        expectedCurrentIndex = 1_100000068703;
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
        uint128 mLatestIndex,
        uint128 enableLatestMIndex,
        uint128 disableIndex,
        uint32 earnerRate,
        uint32 yieldFeeRate,
        uint40 mLatestUpdateTimestamp
    ) internal view returns (uint128) {
        return
            UIntMath.bound128(
                ContinuousIndexingMath.multiplyIndicesDown(
                    (UIntMath.safe128(uint256(disableIndex) * mLatestIndex) / enableLatestMIndex),
                    ContinuousIndexingMath.getContinuousIndex(
                        ContinuousIndexingMath.convertFromBasisPoints(
                            UIntMath.safe32((uint256(earnerRate) * (HUNDRED_PERCENT - yieldFeeRate)) / HUNDRED_PERCENT)
                        ),
                        uint32(block.timestamp - mLatestUpdateTimestamp)
                    )
                )
            );
    }

    function _getMaxAmount(uint128 index_) internal pure returns (uint240) {
        return (uint240(type(uint112).max) * index_) / EXP_SCALED_ONE;
    }

    function _getYieldFee(uint240 yield_, uint16 yieldFeeRate_) internal pure returns (uint240) {
        return yield_ == 0 ? 0 : (yield_ * yieldFeeRate_) / HUNDRED_PERCENT;
    }

    /* ============ Fuzz Utils ============ */

    function _getFuzzedBalances(
        uint128 index_,
        uint240 balanceWithYield_,
        uint240 balance_,
        uint240 maxAmount_
    ) internal pure returns (uint240, uint240) {
        balanceWithYield_ = uint240(bound(balanceWithYield_, 0, maxAmount_));
        balance_ = uint240(bound(balance_, (balanceWithYield_ * EXP_SCALED_ONE) / index_, balanceWithYield_));

        return (balanceWithYield_, balance_);
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
