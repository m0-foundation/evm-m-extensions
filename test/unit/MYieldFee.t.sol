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

    // TODO: add fuzz test
    function test_claimYieldFor() external {
        uint256 yieldAmount = 80e6;
        uint240 aliceBalance = 1_000e6;
        uint128 enableMIndex = 1_100000000000;

        mToken.setBalanceOf(address(mYieldFee), yieldAmount);

        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mYieldFee.setAccountOf(alice, aliceBalance, 1_000e6, enableMIndex);

        vm.expectEmit();
        emit IMYieldFee.YieldClaimed(alice, alice, yieldAmount);

        vm.prank(alice);
        assertEq(mYieldFee.claimYieldFor(alice), yieldAmount);

        assertEq(mYieldFee.balanceOf(alice), aliceBalance + yieldAmount);
        assertEq(mYieldFee.accruedYieldOf(alice), 0);
    }

    /* ============ claimYieldFee ============ */

    function test_claimYieldFee_noYield() external {
        assertEq(mYieldFee.claimYieldFee(), 0);
    }

    // TODO: add fuzz test
    function test_claimYieldFee() external {
        uint256 yieldFeeAmount = 20e6;
        uint240 aliceBalance = 1_000e6;
        uint128 enableMIndex = 1_100000000000;

        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mYieldFee.setTotalPrincipal(1_000e6);
        mYieldFee.setTotalSupply(1_000e6);
        mYieldFee.setAccountOf(alice, aliceBalance, 1_000e6, 800000000000);
        mYieldFee.setLastYieldFeeClaimIndex(200000000000);

        assertEq(mYieldFee.currentIndex(), 1_100000000000);
        assertEq(mYieldFee.yieldIndex(), 880000000000); // 80% of 1_210000000000

        assertEq(mYieldFee.accruedYieldFee(), yieldFeeAmount);

        vm.expectEmit();
        emit IMYieldFee.YieldFeeClaimed(alice, yieldFeeRecipient, yieldFeeAmount);

        vm.prank(alice);
        assertEq(mYieldFee.claimYieldFee(), yieldFeeAmount);

        assertEq(mYieldFee.balanceOf(yieldFeeRecipient), yieldFeeAmount);
        assertEq(mYieldFee.accruedYieldFee(), 0);

        assertEq(mYieldFee.balanceOf(alice), aliceBalance);
        assertEq(mYieldFee.accruedYieldOf(alice), 80e6);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_notApprovedEarner() external {
        vm.expectRevert(abi.encodeWithSelector(IMExtension.NotApprovedEarner.selector, address(mYieldFee)));
        mYieldFee.enableEarning();
    }

    function test_enableEarning() external {
        registrar.setListContains(EARNERS_LIST, address(mYieldFee), true);

        mToken.setCurrentIndex(1_210000000000);

        assertEq(mYieldFee.enableMIndex(), 0);
        assertEq(mYieldFee.currentIndex(), 1_000000000000);

        vm.expectEmit();
        emit IMExtension.EarningEnabled(1_210000000000);

        mYieldFee.enableEarning();

        assertEq(mYieldFee.enableMIndex(), 1_210000000000);
        assertEq(mYieldFee.currentIndex(), 1_000000000000);
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_earningIsDisabled() external {
        vm.expectRevert(IMExtension.EarningIsDisabled.selector);
        mYieldFee.disableEarning();
    }

    function test_disableEarning_approvedEarner() external {
        registrar.setListContains(EARNERS_LIST, address(mYieldFee), true);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.IsApprovedEarner.selector, address(mYieldFee)));
        mYieldFee.disableEarning();
    }

    function test_disableEarning() external {
        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(1_100000000000);

        assertEq(mYieldFee.enableMIndex(), 1_100000000000);
        assertEq(mYieldFee.disableIndex(), 0);
        assertEq(mYieldFee.currentIndex(), 1_100000000000);

        vm.expectEmit();
        emit IMExtension.EarningDisabled(1_100000000000);

        mYieldFee.disableEarning();

        assertEq(mYieldFee.enableMIndex(), 0);
        assertEq(mYieldFee.disableIndex(), 1_100000000000);
        assertEq(mYieldFee.currentIndex(), 1_100000000000);
    }

    /* ============ currentIndex ============ */

    function test_currentIndex() external {
        assertEq(mYieldFee.currentIndex(), EXP_SCALED_ONE);

        mToken.setCurrentIndex(1_331000000000);

        assertEq(mYieldFee.currentIndex(), EXP_SCALED_ONE);

        mYieldFee.setDisableIndex(1_050000000000);

        assertEq(mYieldFee.currentIndex(), 1_050000000000);

        mYieldFee.setDisableIndex(1_100000000000);

        assertEq(mYieldFee.currentIndex(), 1_100000000000);

        mYieldFee.setEnableMIndex(1_100000000000);

        assertEq(mYieldFee.currentIndex(), 1_331000000000);

        mYieldFee.setEnableMIndex(1_155000000000);

        assertEq(mYieldFee.currentIndex(), 1_267619047619);

        mYieldFee.setEnableMIndex(1_210000000000);

        assertEq(mYieldFee.currentIndex(), 1_210000000000);

        mYieldFee.setEnableMIndex(1_270500000000);

        assertEq(mYieldFee.currentIndex(), 1_152380952380);

        mYieldFee.setEnableMIndex(1_331000000000);

        assertEq(mYieldFee.currentIndex(), 1_100000000000);

        mToken.setCurrentIndex(1_464100000000);

        assertEq(mYieldFee.currentIndex(), 1_210000000000);
    }

    /* ============ accruedYieldFee ============ */

    function test_accruedYieldFee_noYield() external {
        assertEq(mYieldFee.accruedYieldFee(), 0);

        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(1_100000000000);

        mYieldFee.setTotalPrincipal(1_000e6);
        mYieldFee.setTotalSupply(1_000e6);

        assertEq(mYieldFee.accruedYieldFee(), 20e6); // accruedYield: 100e6, yieldFee: 20e6

        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRate(0);

        assertEq(mYieldFee.accruedYieldFee(), 0);
    }

    function test_accruedYieldFee() external {
        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(1_100000000000);

        mYieldFee.setTotalPrincipal(1_000e6);
        mYieldFee.setTotalSupply(1_000e6);

        assertEq(mYieldFee.accruedYieldFee(), 20e6); // accruedYield: 100e6, yieldFee: 20e6
    }

    /* ============ accruedYieldOf ============ */

    function test_accruedYieldOf() external {
        uint128 enableMIndex = 1_100000000000;

        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mYieldFee.setAccountOf(alice, 500, 500, enableMIndex); // 550 balance with yield.

        assertEq(mYieldFee.accruedYieldOf(alice), 50 - _getYieldFee(50, YIELD_FEE_RATE));

        mYieldFee.setAccountOf(alice, 1_000, 1_000, enableMIndex); // 1_100 balance with yield.

        assertEq(mYieldFee.accruedYieldOf(alice), 100 - _getYieldFee(100, YIELD_FEE_RATE));

        mToken.setCurrentIndex(1_331000000000);

        assertEq(mYieldFee.accruedYieldOf(alice), 210 - _getYieldFee(210, YIELD_FEE_RATE));

        mYieldFee.setAccountOf(alice, 1_000, 1_500, enableMIndex); // 1_815 balance with yield.

        assertEq(mYieldFee.accruedYieldOf(alice), 815 - _getYieldFee(815, YIELD_FEE_RATE));
    }

    /* ============ balanceOf ============ */

    function test_balanceOf() external {
        uint240 balance = 1_000e6;
        mYieldFee.setAccountOf(alice, balance, 800e6, EXP_SCALED_ONE);

        assertEq(mYieldFee.balanceOf(alice), balance);
    }

    /* ============ balanceWithYieldOf ============ */

    function test_balanceWithYieldOf() external {
        uint128 enableMIndex = 1_100000000000;

        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mYieldFee.setAccountOf(alice, 500, 500, enableMIndex); // 550 balance with yield.

        assertEq(mYieldFee.balanceWithYieldOf(alice), 550 - _getYieldFee(50, YIELD_FEE_RATE));

        mYieldFee.setAccountOf(alice, 1_000, 1_000, enableMIndex); // 1_100 balance with yield.

        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_100 - _getYieldFee(100, YIELD_FEE_RATE));

        mToken.setCurrentIndex(1_331000000000);

        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_210 - _getYieldFee(210, YIELD_FEE_RATE));

        mYieldFee.setAccountOf(alice, 1_000, 1_500, enableMIndex); // 1_815 balance with yield.

        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_815 - _getYieldFee(815, YIELD_FEE_RATE));
    }

    /* ============ principalOf ============ */

    function test_principalOf() external {
        uint112 principal = 800e6;
        mYieldFee.setAccountOf(alice, 1_000e6, principal, EXP_SCALED_ONE);

        assertEq(mYieldFee.principalOf(alice), principal);
    }

    /* ============ projectedSupply ============ */

    function test_projectedSupply() external {
        uint240 totalSupply = 1_000e6;

        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(1_100000000000);

        mYieldFee.setTotalPrincipal(1_000e6);
        mYieldFee.setTotalSupply(totalSupply);

        assertEq(mYieldFee.projectedSupply(), totalSupply + 80e6 + 20e6); // totalSupply + yield + yieldFee
    }

    /* ============ totalAccruedYield ============ */

    function test_totalAccruedYield() external {
        mToken.setCurrentIndex(1_210000000000);
        mYieldFee.setEnableMIndex(1_100000000000);

        mYieldFee.setTotalPrincipal(1_000e6);
        mYieldFee.setTotalSupply(1_000e6);

        assertEq(mYieldFee.totalAccruedYield(), 80e6 + 20e6); // yield + yieldFee
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
        uint128 enableMIndex = 1_100000000000;

        mToken.setCurrentIndex(1_237000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mToken.setBalanceOf(alice, 1_002);
        mToken.setBalanceOf(address(mYieldFee), 1_000);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 25
        mYieldFee.setAccountOf(alice, 1_000, 1_000, enableMIndex);

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
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 888 + 1); // Added principal is rounded up
        assertEq(mYieldFee.totalSupply(), 1_000 + 999);
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1);
        assertEq(mYieldFee.projectedSupply(), 2_125);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1);

        vm.prank(alice);
        mYieldFee.wrap(alice, 1);

        assertEq(mYieldFee.principalOf(alice), 1_000 + 888); // No change due to principal round down on wrap.
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999 + 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 100 - 1);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 100);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 888 + 1 + 1);
        assertEq(mYieldFee.totalSupply(), 1_000 + 999 + 1);
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1);
        assertEq(mYieldFee.projectedSupply(), 2_124 + 2); // rounds up

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 2);

        vm.prank(alice);
        mYieldFee.wrap(alice, 2);

        assertEq(mYieldFee.principalOf(alice), 1_000 + 888 + 1); // Rounds down on wrap.
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999 + 1 + 2);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 100 + 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 100 - 1 - 1);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 888 + 1 + 1 + 2);
        assertEq(mYieldFee.totalSupply(), 1_000 + 999 + 1 + 2);
        assertEq(mYieldFee.totalAccruedYield(), 125 + 1);
        assertEq(mYieldFee.projectedSupply(), 2_124 + 2 + 2);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mYieldFee)), 2002);
    }

    function testFuzz_wrap(
        bool earningEnabled_,
        uint240 balanceWithYield_,
        uint240 balance_,
        uint240 wrapAmount_,
        uint128 currentMIndex_,
        uint128 enableMIndex_,
        uint128 disableIndex_
    ) external {
        (currentMIndex_, enableMIndex_, disableIndex_) = _getFuzzedIndices(
            currentMIndex_,
            enableMIndex_,
            disableIndex_
        );

        uint128 currentIndex = mYieldFee.currentIndex();

        _setupIndices(earningEnabled_, currentMIndex_, enableMIndex_, disableIndex_);
        (balanceWithYield_, balance_) = _getFuzzedBalances(
            currentIndex,
            balanceWithYield_,
            balance_,
            _getMaxAmount(currentIndex)
        );

        uint112 alicePrincipal = _setupAccount(alice, balanceWithYield_, balance_);

        wrapAmount_ = uint240(bound(wrapAmount_, 0, _getMaxAmount(currentIndex) - balanceWithYield_));

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
        alicePrincipal += IndexingMath.getPrincipalAmountRoundedDown(wrapAmount_, currentIndex);

        uint240 aliceBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(alicePrincipal, currentIndex);
        uint240 aliceYield = !earningEnabled_ || (aliceBalanceWithYield <= aliceBalance)
            ? 0
            : aliceBalanceWithYield - aliceBalance;

        uint16 yieldFeeRate = mYieldFee.yieldFeeRate();
        uint240 yieldFee = aliceYield == 0 ? 0 : (aliceYield * yieldFeeRate) / HUNDRED_PERCENT;

        assertEq(mYieldFee.balanceOf(alice), aliceBalance);
        assertEq(mYieldFee.balanceOf(alice), mYieldFee.totalSupply());

        assertApproxEqAbs(mYieldFee.principalOf(alice), mYieldFee.totalPrincipal(), 1); // May round down on wrap.

        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + aliceYield - yieldFee);
        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + mYieldFee.accruedYieldOf(alice));

        // Principal is rounded up when adding to total principal.
        // And projected supply is rounded up when converting total principal to a present amount.
        // TODO: why is the rounding error so high?
        assertApproxEqAbs(mYieldFee.balanceWithYieldOf(alice) + yieldFee, mYieldFee.projectedSupply(), 81);
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

        mYieldFee.setAccountOf(alice, 999, 909, EXP_SCALED_ONE);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldFee.unwrap(alice, 1_000);
    }

    function test_unwrap() external {
        uint128 enableMIndex = 1_100000000000;

        mToken.setCurrentIndex(1_237000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mToken.setBalanceOf(address(mYieldFee), 1_002);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 25
        mYieldFee.setAccountOf(alice, 1_000, 1_000, enableMIndex); // 1_100 balance with yield.

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

        assertEq(mToken.balanceOf(alice), 1000);
        assertEq(mToken.balanceOf(address(mYieldFee)), 2);
    }

    function testFuzz_unwrap(
        bool earningEnabled_,
        uint240 balanceWithYield_,
        uint240 balance_,
        uint240 unwrapAmount_,
        uint128 currentMIndex_,
        uint128 enableMIndex_,
        uint128 disableIndex_
    ) external {
        (currentMIndex_, enableMIndex_, disableIndex_) = _getFuzzedIndices(
            currentMIndex_,
            enableMIndex_,
            disableIndex_
        );

        _setupIndices(earningEnabled_, currentMIndex_, enableMIndex_, disableIndex_);

        (balanceWithYield_, balance_) = _getFuzzedBalances(
            currentMIndex_,
            balanceWithYield_,
            balance_,
            _getMaxAmount(mYieldFee.currentIndex())
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
        uint112 unwrapPrincipalUp = IndexingMath.getPrincipalAmountRoundedUp(unwrapAmount_, mYieldFee.currentIndex());
        alicePrincipal = unwrapPrincipalUp > alicePrincipal ? 0 : alicePrincipal - unwrapPrincipalUp;

        uint240 aliceBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(
            alicePrincipal,
            mYieldFee.currentIndex()
        );

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
        // TODO: why is the rounding error so high?
        assertApproxEqAbs(mYieldFee.balanceWithYieldOf(alice) + yieldFee, mYieldFee.projectedSupply(), 94);
    }

    /* ============ transfer ============ */

    function test_transfer_invalidRecipient() external {
        mYieldFee.setAccountOf(alice, 1_000, 1_000, EXP_SCALED_ONE);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(alice);
        mYieldFee.transfer(address(0), 1_000);
    }

    function test_transfer_insufficientBalance_toSelf() external {
        mYieldFee.setAccountOf(alice, 999, 999, EXP_SCALED_ONE);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldFee.transfer(alice, 1_000);
    }

    function test_transfer_insufficientBalance() external {
        mYieldFee.setAccountOf(alice, 999, 999, EXP_SCALED_ONE);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldFee.transfer(bob, 1_000);
    }

    function test_transfer() external {
        uint128 enableMIndex = 1_100000000000;

        mToken.setCurrentIndex(1_237000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mYieldFee.setTotalPrincipal(1_500);
        mYieldFee.setTotalSupply(1_500);

        // Alice balance with yield: 1_100
        // Balance: 1_000
        // Yield: 124
        // Fee: 25 - 1 = 24 rounded down
        mYieldFee.setAccountOf(alice, 1_000, 1_000, enableMIndex);

        // Bob balance with yield: 550
        // Balance: 500
        // Yield: 62
        // Fee: 12
        mYieldFee.setAccountOf(bob, 500, 500, enableMIndex);

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
        assertEq(mYieldFee.accruedYieldOf(bob), 50 - 1); // Rounds principal down on transfer.

        assertEq(mYieldFee.totalSupply(), 1_500);

        // Principal is rounded up when adding and rounded down when subtracting.
        assertEq(mYieldFee.totalPrincipal(), 1_501);

        // projectedSupply rounds up.
        assertEq(mYieldFee.totalAccruedYield(), 124 + 62 + 2);
        assertEq(mYieldFee.projectedSupply(), 1_500 + 124 + 62 + 2);
    }

    function test_transfer_toSelf() external {
        uint128 enableMIndex = 1_100000000000;

        mToken.setCurrentIndex(1_237000000000);
        mYieldFee.setEnableMIndex(enableMIndex);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 25
        mYieldFee.setAccountOf(alice, 1_000, 1_000, enableMIndex); // 1_100 balance with yield.

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
        bool earningEnabled_,
        uint240 aliceBalanceWithYield_,
        uint240 aliceBalance_,
        uint240 bobBalanceWithYield_,
        uint240 bobBalance_,
        uint128 currentMIndex_,
        uint128 enableMIndex_,
        uint128 disableIndex_,
        uint240 amount_
    ) external {
        (currentMIndex_, enableMIndex_, disableIndex_) = _getFuzzedIndices(
            currentMIndex_,
            enableMIndex_,
            disableIndex_
        );

        _setupIndices(earningEnabled_, currentMIndex_, enableMIndex_, disableIndex_);

        (aliceBalanceWithYield_, aliceBalance_) = _getFuzzedBalances(
            mYieldFee.currentIndex(),
            aliceBalanceWithYield_,
            aliceBalance_,
            _getMaxAmount(mYieldFee.currentIndex())
        );

        uint112 alicePrincipal = _setupAccount(alice, aliceBalanceWithYield_, aliceBalance_);
        (bobBalanceWithYield_, bobBalance_) = _getFuzzedBalances(
            mYieldFee.currentIndex(),
            bobBalanceWithYield_,
            bobBalance_,
            _getMaxAmount(mYieldFee.currentIndex()) - aliceBalanceWithYield_
        );

        uint112 bobPrincipal = _setupAccount(bob, bobBalanceWithYield_, bobBalance_);

        amount_ = uint240(bound(amount_, 0, _getMaxAmount(mYieldFee.currentIndex()) - bobBalanceWithYield_));

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
        alicePrincipal -= IndexingMath.getPrincipalAmountRoundedUp(amount_, mYieldFee.currentIndex()) > alicePrincipal
            ? 0
            : IndexingMath.getPrincipalAmountRoundedUp(amount_, mYieldFee.currentIndex());

        (uint240 aliceBalanceWithYield, uint240 aliceYield) = _getBalanceWithYield(
            aliceBalance_,
            alicePrincipal,
            mYieldFee.currentIndex()
        );

        // TODO: why is there a rounding issue while aliceBalance_ + mYieldFee.accruedYieldOf(alice) is correct?
        assertApproxEqAbs(
            mYieldFee.balanceWithYieldOf(alice),
            aliceBalanceWithYield - _getYieldFee(aliceYield, mYieldFee.yieldFeeRate()),
            50
        );

        assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance_ + mYieldFee.accruedYieldOf(alice));

        bobBalance_ += amount_;
        bobPrincipal += IndexingMath.getPrincipalAmountRoundedDown(amount_, mYieldFee.currentIndex());

        (uint240 bobBalanceWithYield, uint240 bobYield) = _getBalanceWithYield(
            bobBalance_,
            bobPrincipal,
            mYieldFee.currentIndex()
        );

        // TODO: why is there a rounding issue while bobBalance_ + mYieldFee.accruedYieldOf(bob) is correct?
        assertApproxEqAbs(
            mYieldFee.balanceWithYieldOf(bob),
            bobBalanceWithYield - _getYieldFee(bobYield, mYieldFee.yieldFeeRate()),
            77
        );

        assertEq(mYieldFee.balanceWithYieldOf(bob), bobBalance_ + mYieldFee.accruedYieldOf(bob));

        assertEq(mYieldFee.totalSupply(), aliceBalance_ + bobBalance_);
        assertEq(mYieldFee.totalSupply(), mYieldFee.balanceOf(alice) + mYieldFee.balanceOf(bob));

        // Principal added or removed from totalPrincipal is rounded up when adding and rounded down when subtracting.
        assertApproxEqAbs(mYieldFee.totalPrincipal(), alicePrincipal + bobPrincipal, 2);
        assertApproxEqAbs(mYieldFee.totalPrincipal(), mYieldFee.principalOf(alice) + mYieldFee.principalOf(bob), 2);

        // TODO: why is there a rounding issue?
        assertApproxEqAbs(
            mYieldFee.projectedSupply(),
            mYieldFee.balanceWithYieldOf(alice) +
                _getYieldFee(aliceYield, mYieldFee.yieldFeeRate()) +
                mYieldFee.balanceWithYieldOf(bob) +
                _getYieldFee(bobYield, mYieldFee.yieldFeeRate()),
            193
        );
    }

    /* ============ Fuzz Utils ============ */

    function _setupAccount(
        address account_,
        uint240 balanceWithYield_,
        uint240 balance_
    ) internal returns (uint112 principal_) {
        principal_ = IndexingMath.getPrincipalAmountRoundedDown(balanceWithYield_, mYieldFee.currentIndex());

        mYieldFee.setAccountOf(account_, balance_, principal_, mYieldFee.currentIndex());
        mYieldFee.setTotalPrincipal(mYieldFee.totalPrincipal() + principal_);
        mYieldFee.setTotalSupply(mYieldFee.totalSupply() + balance_);
    }

    function _setupIndices(
        bool earningEnabled_,
        uint128 currentMIndex_,
        uint128 enableMIndex_,
        uint128 disableIndex_
    ) internal {
        mToken.setCurrentIndex(currentMIndex_);
        mYieldFee.setDisableIndex(disableIndex_);

        if (earningEnabled_) {
            mToken.setIsEarning(address(mYieldFee), true);
            mYieldFee.setEnableMIndex(enableMIndex_);
        }
    }
}
