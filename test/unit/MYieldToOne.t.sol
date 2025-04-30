// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldToOne } from "../../src/MYieldToOne.sol";

import { IMYieldToOne } from "../../src/interfaces/IMYieldToOne.sol";
import { IMExtension } from "../../src/interfaces/IMExtension.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../lib/common/src/interfaces/IERC20Extended.sol";

import { BaseUnitTest } from "../utils/BaseUnitTest.sol";

contract MYieldToOneUnitTests is BaseUnitTest {
    MYieldToOne public mYieldToOne;

    function setUp() public override {
        super.setUp();

        mYieldToOne = new MYieldToOne(address(mToken), yieldRecipient);
    }

    /* ============ constructor ============ */
    function test_constructor() external view {
        assertEq(mYieldToOne.mToken(), address(mToken));
        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);
        assertEq(mYieldToOne.name(), "HALO USD");
        assertEq(mYieldToOne.symbol(), "HUSD");
        assertEq(mYieldToOne.decimals(), 6);
    }

    function test_constructor_zeroMToken() external {
        vm.expectRevert(IMExtension.ZeroMToken.selector);
        new MYieldToOne(address(0), address(yieldRecipient));
    }

    function test_constructor_zeroYieldRecipient() external {
        vm.expectRevert(IMYieldToOne.ZeroYieldRecipient.selector);
        new MYieldToOne(address(mToken), address(0));
    }

    /* ============ _wrap ============ */

    function test_wrap_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(alice);
        mYieldToOne.wrap(alice, 0);
    }

    function test_wrap_invalidRecipient() external {
        mToken.setBalanceOf(alice, 1_000);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(alice);
        mYieldToOne.wrap(address(0), 1_000);
    }

    function test_wrap() external {
        mToken.setBalanceOf(alice, 2_000);

        assertEq(mToken.balanceOf(alice), 2_000);
        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mYieldToOne.yield(), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(alice, 1_000);

        assertEq(mToken.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_000);
        assertEq(mYieldToOne.yield(), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), bob, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(bob, 1_000);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.totalSupply(), 2_000);
        assertEq(mYieldToOne.balanceOf(bob), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 2_000);
        assertEq(mYieldToOne.yield(), 0);

        // simulate yield accrual by increasing accrued
        mToken.setBalanceOf(address(mYieldToOne), 2_500);
        assertEq(mYieldToOne.yield(), 500);
        assertEq(mYieldToOne.balanceOf(bob), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
    }

    /* ============ wrapWithPermit vrs ============ */

    function test_wrapWithPermit_vrs() external {
        mToken.setBalanceOf(alice, 1_000);

        assertEq(mToken.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1_000);

        vm.startPrank(alice);
        mYieldToOne.wrapWithPermit(alice, 1_000, 0, 0, bytes32(0), bytes32(0));

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.totalSupply(), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_000);
    }

    // /* ============ wrapWithPermit signature ============ */
    function test_wrapWithPermit_signature() external {
        mToken.setBalanceOf(alice, 1_000);

        assertEq(mToken.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1_000);

        vm.startPrank(alice);
        mYieldToOne.wrapWithPermit(alice, 1_000, 0, hex"");

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.totalSupply(), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_000);
    }

    /* ============ _unwrap ============ */
    function test_unwrap_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 0);
    }

    function test_unwrap_insufficientBalance() external {
        mToken.setBalanceOf(alice, 999);
        vm.prank(alice);
        mYieldToOne.wrap(alice, 999);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 1_000);
    }

    function test_unwrap() external {
        mToken.setBalanceOf(alice, 1000);
        vm.prank(alice);
        mYieldToOne.wrap(alice, 1000);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 1_000);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 1);

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 1);

        assertEq(mYieldToOne.totalSupply(), 999);
        assertEq(mYieldToOne.balanceOf(alice), 999);
        assertEq(mToken.balanceOf(alice), 1);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 499);

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 499);

        assertEq(mYieldToOne.totalSupply(), 500);
        assertEq(mYieldToOne.balanceOf(alice), 500);
        assertEq(mToken.balanceOf(alice), 500);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 500);

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 500);

        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 1000);
    }

    /* ============ yield ============ */
    function test_yield() external {
        mToken.setBalanceOf(alice, 1_000);
        mToken.setBalanceOf(bob, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(alice, 1_000);

        vm.prank(bob);
        mYieldToOne.wrap(bob, 1_000);

        assertEq(mYieldToOne.yield(), 0);

        mToken.setBalanceOf(address(mYieldToOne), mYieldToOne.totalSupply() + 500);

        assertEq(mYieldToOne.yield(), 500);
    }

    /* ============ claimYield ============ */
    function test_claimYield_noYield() external {
        vm.expectRevert(IMYieldToOne.NoYield.selector);

        vm.prank(alice);
        mYieldToOne.claimYield();
    }

    function test_claimYield() external {
        mToken.setBalanceOf(alice, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(alice, 1_000);

        mToken.setBalanceOf(address(mYieldToOne), mYieldToOne.totalSupply() + 500);

        assertEq(mYieldToOne.yield(), 500);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(500);

        mYieldToOne.claimYield();

        assertEq(mYieldToOne.yield(), 0);
        assertEq(mToken.balanceOf(address(mYieldToOne)), mYieldToOne.totalSupply());
        assertEq(mToken.balanceOf(yieldRecipient), 500);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_earningEnabled() external {
        mToken.setCurrentIndex(1_100000000000);

        mYieldToOne.enableEarning();

        vm.expectRevert(IMExtension.EarningIsEnabled.selector);
        mYieldToOne.enableEarning();
    }

    function test_enableEarning() external {
        mToken.setCurrentIndex(1_210000000000);

        vm.expectEmit();
        emit IMExtension.EarningEnabled(1_210000000000);

        mYieldToOne.enableEarning();

        assertEq(mYieldToOne.isEarningEnabled(), true);
    }

    /* ============ disableEarning ============ */
    function test_disableEarning_earningIsDisabled() external {
        vm.expectRevert(IMExtension.EarningIsDisabled.selector);
        mYieldToOne.disableEarning();
    }

    function test_disableEarning() external {
        mToken.setCurrentIndex(1_100000000000);
        mYieldToOne.enableEarning();

        mToken.setCurrentIndex(1_200000000000);

        vm.expectEmit();
        emit IMExtension.EarningDisabled(1_200000000000);

        mYieldToOne.disableEarning();

        assertEq(mYieldToOne.isEarningEnabled(), false);
    }
}
