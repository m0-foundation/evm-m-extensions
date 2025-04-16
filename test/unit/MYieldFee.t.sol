// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";
import { UIntMath } from "../../lib/common/src/libs/UIntMath.sol";

import { IMYieldFee } from "../../src/interfaces/IMYieldFee.sol";
import { IMExtension } from "../../src/interfaces/IMExtension.sol";
import { IYieldFee } from "../../src/interfaces/IYieldFee.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../lib/common/src/interfaces/IERC20Extended.sol";

import { MYieldFeeHarness } from "../harness/MYieldFeeHarness.sol";
import { BaseUnitTest } from "../utils/BaseUnitTest.sol";

contract MYieldFeeUnitTests is BaseUnitTest {
    MYieldFeeHarness public mYieldFee;

    function setUp() public override {
        super.setUp();

        mYieldFee = new MYieldFeeHarness(
            "MYieldFee",
            "MYF",
            address(mToken),
            address(registrar),
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            admin,
            yieldFeeManager
        );
    }

    /* ============ constructor ============ */

    function test_constructor() external view {
        assertEq(mYieldFee.HUNDRED_PERCENT(), 10_000);
        assertEq(mYieldFee.yieldFeeRate(), YIELD_FEE_RATE);
        assertEq(mYieldFee.yieldFeeRecipient(), yieldFeeRecipient);
        assertTrue(mYieldFee.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mYieldFee.hasRole(YIELD_FEE_MANAGER_ROLE, yieldFeeManager));
    }

    function test_constructor_zeroMToken() external {
        vm.expectRevert(IMExtension.ZeroMToken.selector);
        new MYieldFeeHarness(
            "MYieldFee",
            "MYF",
            address(0),
            address(registrar),
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            admin,
            yieldFeeManager
        );
    }

    function test_constructor_zeroRegistrar() external {
        vm.expectRevert(IMExtension.ZeroRegistrar.selector);
        new MYieldFeeHarness(
            "MYieldFee",
            "MYF",
            address(mToken),
            address(0),
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            admin,
            yieldFeeManager
        );
    }

    function test_constructor_zeroYieldFeeRecipient() external {
        vm.expectRevert(IYieldFee.ZeroYieldFeeRecipient.selector);
        new MYieldFeeHarness(
            "MYieldFee",
            "MYF",
            address(mToken),
            address(registrar),
            YIELD_FEE_RATE,
            address(0),
            admin,
            yieldFeeManager
        );
    }

    function test_constructor_zeroAdmin() external {
        vm.expectRevert(IYieldFee.ZeroAdmin.selector);
        new MYieldFeeHarness(
            "MYieldFee",
            "MYF",
            address(mToken),
            address(registrar),
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            address(0),
            yieldFeeManager
        );
    }

    function test_constructor_zeroYieldFeeManager() external {
        vm.expectRevert(IYieldFee.ZeroYieldFeeManager.selector);
        new MYieldFeeHarness(
            "MYieldFee",
            "MYF",
            address(mToken),
            address(registrar),
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            admin,
            address(0)
        );
    }

    /* ============ claimYieldFor ============ */

    function test_claimYieldFor_zeroYieldRecipient() external {
        vm.expectRevert(IMYieldFee.ZeroYieldRecipient.selector);
        mYieldFee.claimYieldFor(address(0));
    }

    function test_claimYieldFor_noYield() external {
        assertEq(mYieldFee.claimYieldFor(alice), 0);
    }

    function test_claimYieldFor() external {
        uint256 yieldAmount = 480e6;

        mToken.setBalanceOf(address(mYieldFee), yieldAmount);
        mToken.setCurrentIndex(2e12);

        mYieldFee.setAccountOf(alice, 1_000e6, 800e6);

        assertEq(mYieldFee.claimYieldFor(alice), yieldAmount);
    }

    /* ============ claimYieldFeeFor ============ */

    function test_claimYieldFeeFor_zeroYieldFeeRecipient() external {
        vm.expectRevert(IYieldFee.ZeroYieldFeeRecipient.selector);
        mYieldFee.claimYieldFeeFor(address(0));
    }

    function test_claimYieldFeeFor_noYield() external {
        assertEq(mYieldFee.claimYieldFeeFor(yieldFeeRecipient), 0);
    }

    function test_claimYieldFeeFor() external {
        uint256 yieldFeeAmount = 120e6;

        mToken.setBalanceOf(address(mYieldFee), yieldFeeAmount);
        mToken.setCurrentIndex(2e12);

        mYieldFee.setAccruedYieldFee(yieldFeeRecipient, yieldFeeAmount);

        assertEq(mYieldFee.claimYieldFeeFor(yieldFeeRecipient), yieldFeeAmount);
    }

    /* ============ accruedYieldOf ============ */

    function test_accruedYieldOf() external {
        mToken.setCurrentIndex(2e12);
        mYieldFee.setAccountOf(alice, 1_000e6, 800e6);

        assertEq(mYieldFee.accruedYieldOf(alice), 480e6);
    }

    /* ============ balanceOf ============ */

    function test_balanceOf() external {
        uint240 balance = 1_000e6;
        mYieldFee.setAccountOf(alice, balance, 800e6);

        assertEq(mYieldFee.balanceOf(alice), balance);
    }

    /* ============ balanceWithYieldOf ============ */

    function test_balanceWithYieldOf() external {
        uint240 balance = 1_000e6;

        mToken.setCurrentIndex(2e12);
        mYieldFee.setAccountOf(alice, balance, 800e6);

        assertEq(mYieldFee.balanceWithYieldOf(alice), balance + 480e6);
    }

    /* ============ principalOf ============ */

    function test_principalOf() external {
        uint112 principal = 800e6;
        mYieldFee.setAccountOf(alice, 1_000e6, principal);

        assertEq(mYieldFee.principalOf(alice), principal);
    }

    /* ============ projectedSupply ============ */

    function test_projectedSupply() external {
        uint240 totalSupply = 1_000e6;

        mToken.setCurrentIndex(2e12);
        mYieldFee.setTotalPrincipal(800e6);
        mYieldFee.setTotalSupply(totalSupply);

        assertEq(mYieldFee.projectedSupply(), totalSupply + 480e6 + 120e6); // totalSupply + yield + yieldFee
    }

    /* ============ totalAccruedYield ============ */

    function test_totalAccruedYield() external {
        mToken.setCurrentIndex(2e12);
        mYieldFee.setTotalPrincipal(800e6);
        mYieldFee.setTotalSupply(1_000e6);

        assertEq(mYieldFee.totalAccruedYield(), 480e6 + 120e6); // yield + yieldFee
    }

    /* ============ wrap ============ */

    function test_wrap_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(alice);
        mYieldFee.wrap(alice, 0);
    }

    function test_wrap_invalidRecipient() external {
        mToken.setBalanceOf(alice, 1_000);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(alice);
        mYieldFee.wrap(address(0), 1_000);
    }

    function test_wrap() external {
        mToken.setCurrentIndex(1_125000000000);

        mToken.setBalanceOf(alice, 1_002);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 25
        mYieldFee.setAccountOf(alice, 1_000, 1_000);

        assertEq(mYieldFee.principalOf(alice), 1_000);
        assertEq(mYieldFee.balanceOf(alice), 1_000);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 100);
        assertEq(mYieldFee.totalPrincipal(), 1_000);
        assertEq(mYieldFee.totalSupply(), 1_000);
        assertEq(mYieldFee.totalAccruedYield(), 125);
        assertEq(mYieldFee.projectedSupply(), 1_125);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 999);

        vm.prank(alice);
        mYieldFee.wrap(alice, 999);

        // Index hasn't changed, so yield remains the same.
        assertEq(mYieldFee.principalOf(alice), 1_000 + 888);
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 100);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 888);
        assertEq(mYieldFee.totalSupply(), 1_000 + 999);
        assertEq(mYieldFee.totalAccruedYield(), 125);
        assertEq(mYieldFee.projectedSupply(), 2_124);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1);

        vm.prank(alice);
        mYieldFee.wrap(alice, 1);

        assertEq(mYieldFee.principalOf(alice), 1_000 + 888); // No change due to principal round down on wrap.
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999 + 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 100 + 1);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 888 + 1);
        assertEq(mYieldFee.totalSupply(), 1_000 + 999 + 1);
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1);
        assertEq(mYieldFee.projectedSupply(), 2_124 + 2); // rounds up

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 2);

        vm.prank(alice);
        mYieldFee.wrap(alice, 2);

        assertEq(mYieldFee.principalOf(alice), 1_000 + 888 + 1); // Rounds down on wrap.
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999 + 1 + 2);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 100 + 1 + 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 99);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 888 + 1 + 2);
        assertEq(mYieldFee.totalSupply(), 1_000 + 999 + 1 + 2);
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1);
        assertEq(mYieldFee.projectedSupply(), 2_124 + 2 + 2);
    }

    function testFuzz_wrap(
        uint240 balanceWithYield_,
        uint240 balance_,
        uint240 wrapAmount_,
        uint128 currentMIndex_
    ) external {
        currentMIndex_ = _getFuzzedIndex(currentMIndex_);
        mToken.setCurrentIndex(currentMIndex_);

        (balanceWithYield_, balance_) = _getFuzzedBalances(
            currentMIndex_,
            balanceWithYield_,
            balance_,
            _getMaxAmount(currentMIndex_)
        );

        uint112 alicePrincipal = _setupAccount(alice, balanceWithYield_, balance_);

        wrapAmount_ = uint240(bound(wrapAmount_, 0, _getMaxAmount(mYieldFee.currentIndex()) - balanceWithYield_));

        mToken.setBalanceOf(alice, wrapAmount_);

        if (wrapAmount_ == 0) {
            vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, (0)));
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(address(0), alice, wrapAmount_);
        }

        vm.startPrank(alice);
        mYieldFee.wrap(alice, wrapAmount_);

        if (wrapAmount_ == 0) return;

        uint240 aliceBalance = balance_ + wrapAmount_;
        alicePrincipal += IndexingMath.getPrincipalAmountRoundedDown(wrapAmount_, currentMIndex_);

        uint240 aliceBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(alicePrincipal, currentMIndex_);
        uint240 aliceYield = (aliceBalanceWithYield <= aliceBalance) ? 0 : aliceBalanceWithYield - aliceBalance;

        uint16 yieldFeeRate = mYieldFee.yieldFeeRate();
        uint240 yieldFee = aliceYield == 0 ? 0 : (aliceYield * yieldFeeRate) / HUNDRED_PERCENT;

        assertEq(mYieldFee.balanceOf(alice), aliceBalance);
        assertEq(mYieldFee.balanceOf(alice), mYieldFee.totalSupply());

        assertApproxEqAbs(mYieldFee.principalOf(alice), mYieldFee.totalPrincipal(), 1); // May round down on wrap.

        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + aliceYield - yieldFee);
        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + mYieldFee.accruedYieldOf(alice));

        // Principal is rounded up when adding to total principal.
        // And projected supply is rounded up when converting total principal to a present amount.
        assertApproxEqAbs(mYieldFee.balanceWithYieldOf(alice) + yieldFee, mYieldFee.projectedSupply(), 11);
    }

    /* ============ unwrap ============ */

    function test_unwrap_invalidAmount() external {
        vm.expectRevert(UIntMath.InvalidUInt240.selector);

        vm.prank(alice);
        mYieldFee.unwrap(alice, uint256(type(uint240).max) + 1);
    }

    function test_unwrap_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(alice);
        mYieldFee.unwrap(alice, 0);
    }

    function test_unwrap_insufficientBalance() external {
        mToken.setCurrentIndex(1_125000000000);

        mYieldFee.setAccountOf(alice, 999, 909);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldFee.unwrap(alice, 1_000);
    }

    function test_unwrap() external {
        mToken.setCurrentIndex(1_125000000000);

        mToken.setBalanceOf(address(mYieldFee), 1_002);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 25
        mYieldFee.setAccountOf(alice, 1_000, 1_000); // 1_100 balance with yield.

        assertEq(mYieldFee.principalOf(alice), 1_000);
        assertEq(mYieldFee.balanceOf(alice), 1_000);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);
        assertEq(mYieldFee.totalPrincipal(), 1_000);
        assertEq(mYieldFee.totalSupply(), 1_000);
        assertEq(mYieldFee.totalAccruedYield(), 125);
        assertEq(mYieldFee.projectedSupply(), 1_125);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 1);

        vm.prank(alice);
        mYieldFee.unwrap(alice, 1);

        // Change due to principal round up on unwrap.
        assertEq(mYieldFee.principalOf(alice), 1_000 - 1);
        assertEq(mYieldFee.balanceOf(alice), 1_000 - 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);
        assertEq(mYieldFee.totalPrincipal(), 1_000);
        assertEq(mYieldFee.totalSupply(), 1_000 - 1);
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1);
        assertEq(mYieldFee.projectedSupply(), 1_125);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 499);

        vm.prank(alice);
        mYieldFee.unwrap(alice, 499);

        assertEq(mYieldFee.principalOf(alice), 1_000 - 1 - 444);
        assertEq(mYieldFee.balanceOf(alice), 1_000 - 1 - 499);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);
        assertEq(mYieldFee.totalPrincipal(), 1_000 - 1 - 444 + 2);
        assertEq(mYieldFee.totalSupply(), 1_000 - 1 - 499);
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1 + 1);
        assertEq(mYieldFee.projectedSupply(), 1_125 - 499 + 1);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 500);

        vm.prank(alice);
        mYieldFee.unwrap(alice, 500);

        assertEq(mYieldFee.principalOf(alice), 1_000 - 1 - 444 - 445); // 110
        assertEq(mYieldFee.balanceOf(alice), 1_000 - 1 - 499 - 500); // 0
        assertEq(mYieldFee.accruedYieldOf(alice), 100 - 1);
        assertEq(mYieldFee.totalPrincipal(), 1_000 - 1 - 444 - 445 + 3);
        assertEq(mYieldFee.totalSupply(), 1_000 - 1 - 499 - 500); // 0
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1 + 1 + 1);
        assertEq(mYieldFee.projectedSupply(), 1_125 - 499 - 500 + 1 + 1); // 128
    }

    function testFuzz_unwrap(
        uint240 balanceWithYield_,
        uint240 balance_,
        uint240 unwrapAmount_,
        uint128 currentMIndex_
    ) external {
        currentMIndex_ = _getFuzzedIndex(currentMIndex_);
        mToken.setCurrentIndex(currentMIndex_);

        (balanceWithYield_, balance_) = _getFuzzedBalances(
            currentMIndex_,
            balanceWithYield_,
            balance_,
            _getMaxAmount(currentMIndex_)
        );

        uint112 alicePrincipal = _setupAccount(alice, balanceWithYield_, balance_);

        mToken.setBalanceOf(address(mYieldFee), balance_);

        unwrapAmount_ = uint240(bound(unwrapAmount_, 0, _getMaxAmount(mYieldFee.currentIndex()) - balanceWithYield_));

        if (unwrapAmount_ == 0) {
            vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, (0)));
        } else if (unwrapAmount_ > balance_) {
            vm.expectRevert(
                abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, balance_, unwrapAmount_)
            );
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(alice, address(0), unwrapAmount_);
        }

        vm.startPrank(alice);
        mYieldFee.unwrap(alice, unwrapAmount_);

        if ((unwrapAmount_ == 0) || (unwrapAmount_ > balance_)) return;

        uint240 aliceBalance = balance_ - unwrapAmount_;
        uint112 unwrapPrincipalUp = IndexingMath.getPrincipalAmountRoundedUp(unwrapAmount_, currentMIndex_);
        alicePrincipal = unwrapPrincipalUp > alicePrincipal ? 0 : alicePrincipal - unwrapPrincipalUp;

        uint240 aliceBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(alicePrincipal, currentMIndex_);
        uint240 aliceYield = (aliceBalanceWithYield <= aliceBalance) ? 0 : aliceBalanceWithYield - aliceBalance;

        uint16 yieldFeeRate = mYieldFee.yieldFeeRate();
        uint240 yieldFee = aliceYield == 0 ? 0 : (aliceYield * yieldFeeRate) / HUNDRED_PERCENT;

        assertEq(mYieldFee.balanceOf(alice), aliceBalance);
        assertEq(mYieldFee.balanceOf(alice), mYieldFee.totalSupply());

        assertApproxEqAbs(mYieldFee.principalOf(alice), mYieldFee.totalPrincipal(), 1); // May round up on unwrap.

        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + aliceYield - yieldFee);
        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + mYieldFee.accruedYieldOf(alice));

        // Principal is rounded down when subtracting from total principal.
        // And projected supply is rounded up when converting total principal to a present amount.
        assertApproxEqAbs(mYieldFee.balanceWithYieldOf(alice) + yieldFee, mYieldFee.projectedSupply(), 11);
    }

    /* ============ transfer ============ */

    function test_transfer_invalidRecipient() external {
        mYieldFee.setAccountOf(alice, 1_000, 1_000);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(alice);
        mYieldFee.transfer(address(0), 1_000);
    }

    function test_transfer_insufficientBalance_toSelf() external {
        mYieldFee.setAccountOf(alice, 999, 999);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldFee.transfer(alice, 1_000);
    }

    function test_transfer_insufficientBalance() external {
        mYieldFee.setAccountOf(alice, 999, 999);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldFee.transfer(bob, 1_000);
    }

    function test_transfer() external {
        mToken.setCurrentIndex(1_125000000000);

        mYieldFee.setTotalPrincipal(1_500);
        mYieldFee.setTotalSupply(1_500);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 25
        mYieldFee.setAccountOf(alice, 1_000, 1_000); // 1_100 balance with yield.
        mYieldFee.setAccountOf(bob, 500, 500); // 550 balance with yield.

        assertEq(mYieldFee.accruedYieldOf(alice), 100);
        assertEq(mYieldFee.accruedYieldOf(bob), 50);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, 500);

        vm.prank(alice);
        mYieldFee.transfer(bob, 500);

        assertEq(mYieldFee.principalOf(alice), 555);
        assertEq(mYieldFee.balanceOf(alice), 500);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);

        assertEq(mYieldFee.principalOf(bob), 944);
        assertEq(mYieldFee.balanceOf(bob), 1_000);
        assertEq(mYieldFee.accruedYieldOf(bob), 50);

        assertEq(mYieldFee.totalSupply(), 1_500);

        // Principal is rounded up when adding and rounded down when subtracting.
        assertEq(mYieldFee.totalPrincipal(), 1_501);

        // Rounds down when computing present amount.
        assertEq(mYieldFee.totalAccruedYield(), 150 + 25 + 14);
        assertEq(mYieldFee.projectedSupply(), 1_650 + 25 + 14);
    }

    function test_transfer_toSelf() external {
        mToken.setCurrentIndex(1_125000000000);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 25
        mYieldFee.setAccountOf(alice, 1_000, 1_000); // 1_100 balance with yield.

        assertEq(mYieldFee.balanceOf(alice), 1_000);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);

        vm.expectEmit();
        emit IERC20.Transfer(alice, alice, 500);

        vm.prank(alice);
        mYieldFee.transfer(alice, 500);

        assertEq(mYieldFee.principalOf(alice), 1_000);
        assertEq(mYieldFee.balanceOf(alice), 1_000);
        assertEq(mYieldFee.accruedYieldOf(alice), 100);

        assertEq(mYieldFee.totalPrincipal(), 1_000);
        assertEq(mYieldFee.totalSupply(), 1_000);
        assertEq(mYieldFee.totalAccruedYield(), 125);
        assertEq(mYieldFee.projectedSupply(), 1_125);
    }

    function testFuzz_transfer(
        uint240 aliceBalanceWithYield_,
        uint240 aliceBalance_,
        uint240 bobBalanceWithYield_,
        uint240 bobBalance_,
        uint128 currentMIndex_,
        uint240 amount_
    ) external {
        currentMIndex_ = _getFuzzedIndex(currentMIndex_);
        mToken.setCurrentIndex(currentMIndex_);

        (aliceBalanceWithYield_, aliceBalance_) = _getFuzzedBalances(
            currentMIndex_,
            aliceBalanceWithYield_,
            aliceBalance_,
            _getMaxAmount(currentMIndex_)
        );

        uint112 alicePrincipal = _setupAccount(alice, aliceBalanceWithYield_, aliceBalance_);

        (bobBalanceWithYield_, bobBalance_) = _getFuzzedBalances(
            currentMIndex_,
            bobBalanceWithYield_,
            bobBalance_,
            _getMaxAmount(currentMIndex_) - aliceBalanceWithYield_
        );

        uint112 bobPrincipal = _setupAccount(bob, bobBalanceWithYield_, bobBalance_);

        amount_ = uint240(bound(amount_, 0, _getMaxAmount(currentMIndex_) - bobBalanceWithYield_));

        if (amount_ > aliceBalance_) {
            vm.expectRevert(
                abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, aliceBalance_, amount_)
            );
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(alice, bob, amount_);
        }

        vm.prank(alice);
        mYieldFee.transfer(bob, amount_);

        if (amount_ > aliceBalance_) return;

        assertEq(mYieldFee.balanceOf(alice), aliceBalance_ - amount_);
        assertEq(mYieldFee.balanceOf(bob), bobBalance_ + amount_);

        aliceBalance_ -= amount_;
        alicePrincipal -= IndexingMath.getPrincipalAmountRoundedUp(amount_, currentMIndex_) > alicePrincipal
            ? 0
            : IndexingMath.getPrincipalAmountRoundedUp(amount_, currentMIndex_);

        (uint240 aliceBalanceWithYield, uint240 aliceYield) = _getBalanceWithYield(
            aliceBalance_,
            alicePrincipal,
            currentMIndex_
        );

        // TODO: why is there a rounding issue while aliceBalance_ + mYieldFee.accruedYieldOf(alice) is correct?
        assertApproxEqAbs(
            mYieldFee.balanceWithYieldOf(alice),
            aliceBalanceWithYield - _getYieldFee(aliceYield, mYieldFee.yieldFeeRate()),
            13
        );

        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance_ + mYieldFee.accruedYieldOf(alice));

        bobBalance_ += amount_;
        bobPrincipal += IndexingMath.getPrincipalAmountRoundedDown(amount_, currentMIndex_);

        (uint240 bobBalanceWithYield, uint240 bobYield) = _getBalanceWithYield(
            bobBalance_,
            bobPrincipal,
            currentMIndex_
        );

        // TODO: why is there a rounding issue while bobBalance_ + mYieldFee.accruedYieldOf(bob) is correct?
        assertApproxEqAbs(
            mYieldFee.balanceWithYieldOf(bob),
            bobBalanceWithYield - _getYieldFee(bobYield, mYieldFee.yieldFeeRate()),
            16
        );

        assertEq(mYieldFee.balanceWithYieldOf(bob), bobBalance_ + mYieldFee.accruedYieldOf(bob));

        assertEq(mYieldFee.totalSupply(), aliceBalance_ + bobBalance_);
        assertEq(mYieldFee.totalSupply(), mYieldFee.balanceOf(alice) + mYieldFee.balanceOf(bob));

        // Principal added or removed from totalPrincipal is rounded up when adding and rounded down when subtracting.
        assertApproxEqAbs(mYieldFee.totalPrincipal(), alicePrincipal + bobPrincipal, 2);
        assertApproxEqAbs(mYieldFee.totalPrincipal(), mYieldFee.principalOf(alice) + mYieldFee.principalOf(bob), 2);

        assertApproxEqAbs(
            mYieldFee.projectedSupply(),
            mYieldFee.balanceWithYieldOf(alice) +
                _getYieldFee(aliceYield, mYieldFee.yieldFeeRate()) +
                mYieldFee.balanceWithYieldOf(bob) +
                _getYieldFee(bobYield, mYieldFee.yieldFeeRate()),
            22
        );
    }

    /* ============ Fuzz Utils ============ */

    function _setupAccount(
        address account_,
        uint240 balanceWithYield_,
        uint240 balance_
    ) internal returns (uint112 principal_) {
        principal_ = IndexingMath.getPrincipalAmountRoundedDown(balanceWithYield_, mYieldFee.currentIndex());

        mYieldFee.setAccountOf(account_, balance_, principal_);
        mYieldFee.setTotalPrincipal(mYieldFee.totalPrincipal() + principal_);
        mYieldFee.setTotalSupply(mYieldFee.totalSupply() + balance_);
    }
}
