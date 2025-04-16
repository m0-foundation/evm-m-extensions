// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";

import { MockM, MockRegistrar } from "../utils/Mocks.sol";

contract BaseUnitTest is Test {
    uint16 public constant HUNDRED_PERCENT = 10_000;
    uint16 public constant YIELD_FEE_RATE = 2000; // 20%

    bytes32 public constant EARNERS_LIST = "earners";
    uint56 public constant EXP_SCALED_ONE = 1e12;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant YIELD_FEE_MANAGER_ROLE = keccak256("YIELD_FEE_MANAGER_ROLE");

    MockM public mToken;
    MockRegistrar public registrar;

    address public admin = makeAddr("admin");
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
        registrar = new MockRegistrar();

        (alice, aliceKey) = makeAddrAndKey("alice");
        accounts = [alice, bob, charlie, david];
    }

    /* ============ Utils ============ */

    function _getBalanceWithYield(
        uint240 balance_,
        uint112 principal_,
        uint128 index_
    ) internal pure returns (uint240 balanceWithYield_, uint240 yield_) {
        balanceWithYield_ = IndexingMath.getPresentAmountRoundedDown(principal_, index_);
        yield_ = (balanceWithYield_ <= balance_) ? 0 : balanceWithYield_ - balance_;
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
    ) internal view returns (uint240, uint240) {
        balanceWithYield_ = uint240(bound(balanceWithYield_, 0, maxAmount_));
        balance_ = uint240(bound(balance_, (balanceWithYield_ * EXP_SCALED_ONE) / index_, balanceWithYield_));

        return (balanceWithYield_, balance_);
    }

    function _getFuzzedIndex(uint128 index_) internal view returns (uint128) {
        return uint128(bound(index_, EXP_SCALED_ONE, 10 * EXP_SCALED_ONE));
    }
}
