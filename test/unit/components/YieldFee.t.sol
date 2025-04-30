// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IAccessControl } from "../../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { IndexingMath } from "../../../lib/common/src/libs/IndexingMath.sol";

import { IYieldFee } from "../../../src/interfaces/IYieldFee.sol";

import { YieldFeeHarness } from "../../harness/YieldFeeHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract YieldFeeUnitTests is BaseUnitTest {
    YieldFeeHarness public yieldFee;

    function setUp() public override {
        super.setUp();

        yieldFee = new YieldFeeHarness(YIELD_FEE_RATE, yieldFeeRecipient, admin, yieldFeeManager);
    }

    /* ============ constructor ============ */

    function test_constructor() external view {
        assertEq(yieldFee.HUNDRED_PERCENT(), 10_000);
        assertEq(yieldFee.yieldFeeRate(), YIELD_FEE_RATE);
        assertEq(yieldFee.yieldFeeRecipient(), yieldFeeRecipient);
        assertTrue(yieldFee.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(yieldFee.hasRole(YIELD_FEE_MANAGER_ROLE, yieldFeeManager));
    }

    function test_constructor_zeroYieldFeeRecipient() external {
        vm.expectRevert(IYieldFee.ZeroYieldFeeRecipient.selector);
        new YieldFeeHarness(YIELD_FEE_RATE, address(0), admin, yieldFeeManager);
    }

    function test_constructor_zeroAdmin() external {
        vm.expectRevert(IYieldFee.ZeroAdmin.selector);
        new YieldFeeHarness(YIELD_FEE_RATE, yieldFeeRecipient, address(0), yieldFeeManager);
    }

    function test_constructor_zeroYieldFeeManager() external {
        vm.expectRevert(IYieldFee.ZeroYieldFeeManager.selector);
        new YieldFeeHarness(YIELD_FEE_RATE, yieldFeeRecipient, admin, address(0));
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
        yieldFee.setYieldFeeRate(0);
    }

    function test_setYieldFeeRate_yieldFeeRateTooHigh() external {
        vm.expectRevert(
            abi.encodeWithSelector(IYieldFee.YieldFeeRateTooHigh.selector, HUNDRED_PERCENT + 1, HUNDRED_PERCENT)
        );

        vm.prank(yieldFeeManager);
        yieldFee.setYieldFeeRate(HUNDRED_PERCENT + 1);
    }

    function test_setYieldFeeRate_noUpdate() external {
        assertEq(yieldFee.yieldFeeRate(), YIELD_FEE_RATE);

        vm.prank(yieldFeeManager);
        yieldFee.setYieldFeeRate(YIELD_FEE_RATE);

        assertEq(yieldFee.yieldFeeRate(), YIELD_FEE_RATE);
    }

    function test_setYieldFeeRate() external {
        // Reset rate
        vm.prank(yieldFeeManager);
        yieldFee.setYieldFeeRate(0);

        vm.expectEmit();
        emit IYieldFee.YieldFeeRateSet(YIELD_FEE_RATE);

        vm.prank(yieldFeeManager);
        yieldFee.setYieldFeeRate(YIELD_FEE_RATE);

        assertEq(yieldFee.yieldFeeRate(), YIELD_FEE_RATE);
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
        yieldFee.setYieldFeeRecipient(alice);
    }

    function test_setYieldFeeRecipient_zeroYieldFeeRecipient() external {
        vm.expectRevert(IYieldFee.ZeroYieldFeeRecipient.selector);

        vm.prank(yieldFeeManager);
        yieldFee.setYieldFeeRecipient(address(0));
    }

    function test_setYieldFeeRecipient_noUpdate() external {
        assertEq(yieldFee.yieldFeeRecipient(), yieldFeeRecipient);

        vm.prank(yieldFeeManager);
        yieldFee.setYieldFeeRecipient(yieldFeeRecipient);

        assertEq(yieldFee.yieldFeeRecipient(), yieldFeeRecipient);
    }

    function test_setYieldFeeRecipient() external {
        address newYieldFeeRecipient = makeAddr("newYieldFeeRecipient");

        vm.expectEmit();
        emit IYieldFee.YieldFeeRecipientSet(newYieldFeeRecipient);

        vm.prank(yieldFeeManager);
        yieldFee.setYieldFeeRecipient(newYieldFeeRecipient);

        assertEq(yieldFee.yieldFeeRecipient(), newYieldFeeRecipient);
    }

    /* ============ getAccruedYield ============ */

    // function test_getAccruedYield_noYield() external {
    //     assertEq(yieldFee.getAccruedYield(1_000e6, 1_000e6, EXP_SCALED_ONE, EXP_SCALED_ONE), 0);
    // }
    //
    // function test_getAccruedYield_noFee() external {
    //     vm.prank(yieldFeeManager);
    //     yieldFee.setYieldFeeRate(0);
    //
    //     assertEq(yieldFee.getAccruedYield(1_000e6, 800e6, 2e12, EXP_SCALED_ONE), 600e6); // 1_600e6 - 1_000e6
    // }
    //
    // function test_getAccruedYield_maxFee() external {
    //     vm.prank(yieldFeeManager);
    //     yieldFee.setYieldFeeRate(HUNDRED_PERCENT);
    //
    //     assertEq(yieldFee.getAccruedYield(1_000e6, 800e6, 2e12, EXP_SCALED_ONE), 0);
    // }
    //
    // function test_getAccruedYield() external {
    //     assertEq(yieldFee.getAccruedYield(1_000e6, 800e6, 2e12, EXP_SCALED_ONE), 480e6);
    // }
    //
    // function testFuzz_getAccruedYield(
    //     uint240 balance_,
    //     uint112 principal_,
    //     uint128 currentIndex_,
    //     uint128 lastClaimIndex_,
    //     uint16 yieldFeeRate_
    // ) external {
    //     yieldFeeRate_ = uint16(bound(yieldFeeRate_, 0, HUNDRED_PERCENT));
    //
    //     vm.prank(yieldFeeManager);
    //     yieldFee.setYieldFeeRate(yieldFeeRate_);
    //
    //     uint128 index_ = currentIndex_ > lastClaimIndex_ ? currentIndex_ - lastClaimIndex_ : 0;
    //     uint240 expectedYield_ = IndexingMath.getPresentAmountRoundedDown(principal_, index_);
    //     uint240 expectedYieldFee_ = (expectedYield_ * yieldFeeRate_) / HUNDRED_PERCENT;
    //
    //     assertEq(
    //         yieldFee.getAccruedYield(balance_, principal_, currentIndex_, lastClaimIndex_),
    //         expectedYield_ - expectedYieldFee_
    //     );
    // }
}
