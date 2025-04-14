// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IAccessControl } from "../../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { IndexingMath } from "../../../lib/common/src/libs/IndexingMath.sol";

import { IYieldFeeComponent } from "../../../src/interfaces/IYieldFeeComponent.sol";

import { YieldFeeComponentHarness } from "../../harness/YieldFeeComponentHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract YieldFeeComponentUnitTests is BaseUnitTest {
    YieldFeeComponentHarness public yieldFeeComponent;

    function setUp() public override {
        super.setUp();

        yieldFeeComponent = new YieldFeeComponentHarness(YIELD_FEE_RATE, yieldFeeRecipient, admin, yieldFeeManager);
    }

    /* ============ constructor ============ */

    function test_constructor() external view {
        assertEq(yieldFeeComponent.HUNDRED_PERCENT(), 10_000);
        assertEq(yieldFeeComponent.yieldFeeRate(), YIELD_FEE_RATE);
        assertEq(yieldFeeComponent.yieldFeeRecipient(), yieldFeeRecipient);
        assertTrue(yieldFeeComponent.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(yieldFeeComponent.hasRole(YIELD_FEE_MANAGER_ROLE, yieldFeeManager));
    }

    function test_constructor_zeroYieldFeeRecipient() external {
        vm.expectRevert(IYieldFeeComponent.ZeroYieldFeeRecipient.selector);
        new YieldFeeComponentHarness(YIELD_FEE_RATE, address(0), admin, yieldFeeManager);
    }

    function test_constructor_zeroAdmin() external {
        vm.expectRevert(IYieldFeeComponent.ZeroAdmin.selector);
        new YieldFeeComponentHarness(YIELD_FEE_RATE, yieldFeeRecipient, address(0), yieldFeeManager);
    }

    function test_constructor_zeroYieldFeeManager() external {
        vm.expectRevert(IYieldFeeComponent.ZeroYieldFeeManager.selector);
        new YieldFeeComponentHarness(YIELD_FEE_RATE, yieldFeeRecipient, admin, address(0));
    }

    /* ============ setYieldFeeRate ============ */

    function test_setYieldFeeRate_onlyYieldFeeManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                YIELD_FEE_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        yieldFeeComponent.setYieldFeeRate(0);
    }

    function test_setYieldFeeRate_yieldFeeRateTooHigh() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldFeeComponent.YieldFeeRateTooHigh.selector,
                HUNDRED_PERCENT + 1,
                HUNDRED_PERCENT
            )
        );

        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRate(HUNDRED_PERCENT + 1);
    }

    function test_setYieldFeeRate_noUpdate() external {
        assertEq(yieldFeeComponent.yieldFeeRate(), YIELD_FEE_RATE);

        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRate(YIELD_FEE_RATE);

        assertEq(yieldFeeComponent.yieldFeeRate(), YIELD_FEE_RATE);
    }

    function test_setYieldFeeRate() external {
        // Reset rate
        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRate(0);

        vm.expectEmit();
        emit IYieldFeeComponent.YieldFeeRateSet(YIELD_FEE_RATE);

        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRate(YIELD_FEE_RATE);

        assertEq(yieldFeeComponent.yieldFeeRate(), YIELD_FEE_RATE);
    }

    /* ============ setYieldFeeRecipient ============ */

    function test_setYieldFeeRecipient_onlyYieldFeeManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                YIELD_FEE_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        yieldFeeComponent.setYieldFeeRecipient(alice);
    }

    function test_setYieldFeeRecipient_zeroYieldFeeRecipient() external {
        vm.expectRevert(IYieldFeeComponent.ZeroYieldFeeRecipient.selector);

        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRecipient(address(0));
    }

    function test_setYieldFeeRecipient_noUpdate() external {
        assertEq(yieldFeeComponent.yieldFeeRecipient(), yieldFeeRecipient);

        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRecipient(yieldFeeRecipient);

        assertEq(yieldFeeComponent.yieldFeeRecipient(), yieldFeeRecipient);
    }

    function test_setYieldFeeRecipient() external {
        address newYieldFeeRecipient = makeAddr("newYieldFeeRecipient");

        vm.expectEmit();
        emit IYieldFeeComponent.YieldFeeRecipientSet(newYieldFeeRecipient);

        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRecipient(newYieldFeeRecipient);

        assertEq(yieldFeeComponent.yieldFeeRecipient(), newYieldFeeRecipient);
    }

    /* ============ accruedYieldFeeOf ============ */

    function test_accruedYieldFeeOf() external {
        assertEq(yieldFeeComponent.accruedYieldFeeOf(yieldFeeRecipient), 0);

        uint256 accruedYieldFee = 1_000e6;

        yieldFeeComponent.setAccruedYieldFee(yieldFeeRecipient, accruedYieldFee);

        assertEq(yieldFeeComponent.accruedYieldFeeOf(yieldFeeRecipient), accruedYieldFee);
    }

    /* ============ getAccruedYield ============ */

    function test_getAccruedYield_noYield() external {
        (uint240 yield_, uint240 yieldFee_) = yieldFeeComponent.getAccruedYield(1_000e6, 1_000e6, 1e12);

        assertEq(yield_, 0);
        assertEq(yieldFee_, 0);
    }

    function test_getAccruedYield_noFee() external {
        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRate(0);

        (uint240 yield_, uint240 yieldFee_) = yieldFeeComponent.getAccruedYield(1_000e6, 800e6, 2e12);

        assertEq(yield_, 600e6); // 1_600e6 - 1_000e6
        assertEq(yieldFee_, 0);
    }

    function test_getAccruedYield_maxFee() external {
        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRate(HUNDRED_PERCENT);

        (uint240 yield_, uint240 yieldFee_) = yieldFeeComponent.getAccruedYield(1_000e6, 800e6, 2e12);

        assertEq(yield_, 0);
        assertEq(yieldFee_, 600e6); // 1_600e6 - 1_000e6
    }

    function test_getAccruedYield() external {
        (uint240 yield_, uint240 yieldFee_) = yieldFeeComponent.getAccruedYield(1_000e6, 800e6, 2e12);

        assertEq(yield_, 480e6);
        assertEq(yieldFee_, 120e6); // 600e6 * 0.2
    }

    function testFuzz_getAccruedYield(
        uint240 balance_,
        uint112 principal_,
        uint128 currentIndex_,
        uint16 yieldFeeRate_
    ) external {
        yieldFeeRate_ = uint16(bound(yieldFeeRate_, 0, HUNDRED_PERCENT));

        vm.prank(yieldFeeManager);
        yieldFeeComponent.setYieldFeeRate(yieldFeeRate_);

        (uint240 yield_, uint240 yieldFee_) = yieldFeeComponent.getAccruedYield(balance_, principal_, currentIndex_);

        uint240 balanceWithYield_ = IndexingMath.getPresentAmountRoundedDown(principal_, currentIndex_);
        uint240 expectedYield_ = balanceWithYield_ <= balance_ ? 0 : balanceWithYield_ - balance_;
        uint240 expectedYieldFee_ = (expectedYield_ * yieldFeeRate_) / HUNDRED_PERCENT;

        assertEq(yield_, expectedYield_ - expectedYieldFee_);
        assertEq(yieldFee_, expectedYieldFee_);
    }
}
