// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;
import { console } from "../../lib/forge-std/src/console.sol";
import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";
import { UIntMath } from "../../lib/common/src/libs/UIntMath.sol";

import { IAccessControl } from "../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { IMExtension } from "../../src/interfaces/IMExtension.sol";
import { IMYieldFee } from "../../src/interfaces/IMYieldFee.sol";

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
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            admin,
            yieldFeeManager
        );
    }

    /* ============ constructor ============ */

    function test_constructor() external view {
        assertEq(mYieldFee.HUNDRED_PERCENT(), 10_000);
        assertEq(mYieldFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(mYieldFee.yieldFeeRate(), YIELD_FEE_RATE);
        assertEq(mYieldFee.yieldFeeRecipient(), yieldFeeRecipient);
        assertTrue(mYieldFee.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mYieldFee.hasRole(YIELD_FEE_MANAGER_ROLE, yieldFeeManager));
    }

    function test_constructor_zeroMToken() external {
        vm.expectRevert(IMExtension.ZeroMToken.selector);
        new MYieldFeeHarness("MYieldFee", "MYF", address(0), YIELD_FEE_RATE, yieldFeeRecipient, admin, yieldFeeManager);
    }

    function test_constructor_zeroYieldFeeRecipient() external {
        vm.expectRevert(IMYieldFee.ZeroYieldFeeRecipient.selector);
        new MYieldFeeHarness("MYieldFee", "MYF", address(mToken), YIELD_FEE_RATE, address(0), admin, yieldFeeManager);
    }

    function test_constructor_zeroAdmin() external {
        vm.expectRevert(IMYieldFee.ZeroAdmin.selector);
        new MYieldFeeHarness(
            "MYieldFee",
            "MYF",
            address(mToken),
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            address(0),
            yieldFeeManager
        );
    }

    function test_constructor_zeroYieldFeeManager() external {
        vm.expectRevert(IMYieldFee.ZeroYieldFeeManager.selector);
        new MYieldFeeHarness("MYieldFee", "MYF", address(mToken), YIELD_FEE_RATE, yieldFeeRecipient, admin, address(0));
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
        uint240 yieldAmount = 79_230399;
        uint240 aliceBalance = 1_000e6;

        mToken.setBalanceOf(address(mYieldFee), yieldAmount);
        mYieldFee.setAccountOf(alice, aliceBalance, 1_000e6);
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        vm.expectEmit();
        emit IMYieldFee.YieldClaimed(alice, alice, yieldAmount);

        vm.prank(alice);
        assertEq(mYieldFee.claimYieldFor(alice), yieldAmount);

        aliceBalance += yieldAmount;

        assertEq(mYieldFee.balanceOf(alice), aliceBalance);
        assertEq(mYieldFee.accruedYieldOf(alice), 0);

        // Another 10% index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(mYieldFee.currentIndex(), 1_164738254609);

        yieldAmount = 85_507855;

        vm.expectEmit();
        emit IMYieldFee.YieldClaimed(alice, alice, yieldAmount);

        vm.prank(alice);
        assertEq(mYieldFee.claimYieldFor(alice), yieldAmount);

        aliceBalance += yieldAmount;

        assertEq(mYieldFee.balanceOf(alice), aliceBalance);
        assertEq(mYieldFee.accruedYieldOf(alice), 0);
    }

    /* ============ claimYieldFee ============ */

    function test_claimYieldFee_noYield() external {
        assertEq(mYieldFee.claimYieldFee(), 0);
    }

    // TODO: add fuzz test
    function test_claimYieldFee() external {
        uint256 yieldFeeAmount = 20_769601;

        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        // 1_100e6 balance with yield without fee.
        mYieldFee.setTotalSupply(1_000e6);
        mYieldFee.setTotalPrincipal(1_000e6);
        assertEq(mYieldFee.totalAccruedYield(), 79_230399); // Should be 100 - 100 * 20% = 80 but it rounds down

        mToken.setBalanceOf(address(mYieldFee), 1_100e6);
        assertEq(mYieldFee.totalAccruedYieldFee(), yieldFeeAmount);

        vm.expectEmit();
        emit IMYieldFee.YieldFeeClaimed(alice, yieldFeeRecipient, yieldFeeAmount);

        vm.prank(alice);
        assertEq(mYieldFee.claimYieldFee(), yieldFeeAmount);

        assertEq(mYieldFee.balanceOf(yieldFeeRecipient), yieldFeeAmount);
        assertEq(mYieldFee.totalAccruedYieldFee(), 0);

        // Another 10% index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(mYieldFee.currentIndex(), 1_164738254609);

        assertEq(mYieldFee.totalAccruedYield(), 166_383838);

        uint256 secondYieldFeeAmount = 22_846561;

        // 1_210e6 balance with yield without fee.
        mToken.setBalanceOf(address(mYieldFee), 1_210e6);
        assertEq(mYieldFee.totalAccruedYieldFee(), secondYieldFeeAmount);

        vm.expectEmit();
        emit IMYieldFee.YieldFeeClaimed(alice, yieldFeeRecipient, secondYieldFeeAmount);

        vm.prank(alice);
        assertEq(mYieldFee.claimYieldFee(), secondYieldFeeAmount);

        assertEq(mYieldFee.balanceOf(yieldFeeRecipient), yieldFeeAmount + secondYieldFeeAmount);
        assertEq(mYieldFee.totalAccruedYieldFee(), 0);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_earningIsEnabled() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.EarningIsEnabled.selector));
        mYieldFee.enableEarning();
    }

    function test_enableEarning() external {
        assertEq(mYieldFee.currentIndex(), EXP_SCALED_ONE);
        assertEq(mYieldFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(mYieldFee.latestRate(), 0);

        vm.expectEmit();
        emit IMExtension.EarningEnabled(EXP_SCALED_ONE);

        mYieldFee.enableEarning();

        assertEq(mYieldFee.currentIndex(), EXP_SCALED_ONE);
        assertEq(mYieldFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(mYieldFee.latestRate(), mYiedFeeEarnerRate);

        vm.warp(30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_earningIsDisabled() external {
        vm.expectRevert(IMExtension.EarningIsDisabled.selector);
        mYieldFee.disableEarning();
    }

    function test_disableEarning() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);
        mYieldFee.setLatestIndex(1_100000000000);

        assertEq(mYieldFee.currentIndex(), 1_100000000000);
        assertEq(mYieldFee.latestIndex(), 1_100000000000);
        assertEq(mYieldFee.latestRate(), mYiedFeeEarnerRate);

        vm.warp(30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_187153439146);

        vm.expectEmit();
        emit IMYieldFee.EarningDisabled(1_187153439146);

        mYieldFee.disableEarning();

        assertFalse(mYieldFee.isEarningEnabled());
        assertEq(mYieldFee.currentIndex(), 1_187153439146);
        assertEq(mYieldFee.latestIndex(), 1_187153439146);
        assertEq(mYieldFee.latestRate(), 0);

        vm.warp(30_057_038 * 2);

        // Index should not change
        assertEq(mYieldFee.currentIndex(), 1_187153439146);
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
        mYieldFee.setYieldFeeRate(0);
    }

    function test_setYieldFeeRate_yieldFeeRateTooHigh() external {
        vm.expectRevert(
            abi.encodeWithSelector(IMYieldFee.YieldFeeRateTooHigh.selector, HUNDRED_PERCENT + 1, HUNDRED_PERCENT)
        );

        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRate(HUNDRED_PERCENT + 1);
    }

    function test_setYieldFeeRate_noUpdate() external {
        assertEq(mYieldFee.yieldFeeRate(), YIELD_FEE_RATE);

        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRate(YIELD_FEE_RATE);

        assertEq(mYieldFee.yieldFeeRate(), YIELD_FEE_RATE);
    }

    function test_setYieldFeeRate() external {
        // Reset rate
        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRate(0);

        vm.expectEmit();
        emit IMYieldFee.YieldFeeRateSet(YIELD_FEE_RATE);

        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRate(YIELD_FEE_RATE);

        assertEq(mYieldFee.yieldFeeRate(), YIELD_FEE_RATE);
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
        mYieldFee.setYieldFeeRecipient(alice);
    }

    function test_setYieldFeeRecipient_zeroYieldFeeRecipient() external {
        vm.expectRevert(IMYieldFee.ZeroYieldFeeRecipient.selector);

        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRecipient(address(0));
    }

    function test_setYieldFeeRecipient_noUpdate() external {
        assertEq(mYieldFee.yieldFeeRecipient(), yieldFeeRecipient);

        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRecipient(yieldFeeRecipient);

        assertEq(mYieldFee.yieldFeeRecipient(), yieldFeeRecipient);
    }

    function test_setYieldFeeRecipient() external {
        address newYieldFeeRecipient = makeAddr("newYieldFeeRecipient");

        vm.expectEmit();
        emit IMYieldFee.YieldFeeRecipientSet(newYieldFeeRecipient);

        vm.prank(yieldFeeManager);
        mYieldFee.setYieldFeeRecipient(newYieldFeeRecipient);

        assertEq(mYieldFee.yieldFeeRecipient(), newYieldFeeRecipient);
    }

    /* ============ currentIndex ============ */

    function test_currentIndex() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        uint256 expectedIndex = EXP_SCALED_ONE;
        assertEq(mYieldFee.currentIndex(), expectedIndex);

        uint256 nextTimestamp = vm.getBlockTimestamp() + 365 days;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(EXP_SCALED_ONE, mYiedFeeEarnerRate, startTimestamp);

        assertEq(mYieldFee.currentIndex(), expectedCurrentIndex);
        assertEq(mYieldFee.updateIndex(), expectedCurrentIndex);

        uint40 previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 2;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(expectedCurrentIndex, mYiedFeeEarnerRate, previousTimestamp);

        assertEq(mYieldFee.currentIndex(), expectedCurrentIndex);

        // Half the earner rate
        mToken.setEarnerRate(M_EARNER_RATE / 2);
        mYiedFeeEarnerRate = _getEarnerRate(M_EARNER_RATE / 2, YIELD_FEE_RATE);

        assertEq(mYieldFee.updateIndex(), expectedCurrentIndex);
        assertEq(mYieldFee.latestRate(), mYiedFeeEarnerRate);

        previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 3;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(expectedCurrentIndex, mYiedFeeEarnerRate, previousTimestamp);

        assertEq(mYieldFee.currentIndex(), expectedCurrentIndex);
        assertEq(mYieldFee.updateIndex(), expectedCurrentIndex);

        // Disable earning
        mYieldFee.disableEarning();

        previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 4;
        vm.warp(nextTimestamp);

        // Index should not change
        assertEq(mYieldFee.currentIndex(), expectedCurrentIndex);

        // Re-enable earning
        mToken.setEarnerRate(M_EARNER_RATE);
        mYieldFee.enableEarning();

        mYiedFeeEarnerRate = _getEarnerRate(M_EARNER_RATE, YIELD_FEE_RATE);
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        assertEq(mYieldFee.updateIndex(), expectedCurrentIndex);

        // Index was just re-enabled, so value should still be the same
        assertEq(mYieldFee.currentIndex(), expectedCurrentIndex);

        previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 5;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(expectedCurrentIndex, mYiedFeeEarnerRate, previousTimestamp);
        assertEq(mYieldFee.currentIndex(), expectedCurrentIndex);
        assertEq(mYieldFee.updateIndex(), expectedCurrentIndex);
    }

    /* ============ accruedYieldOf ============ */

    // TODO: add fuzz test
    function test_accruedYieldOf() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        mYieldFee.setAccountOf(alice, 500, 500); // 550 balance with yield without fee.
        assertEq(mYieldFee.accruedYieldOf(alice), 39); // Should be 50 - 50 * 20% = 40 but it rounds down.

        mYieldFee.setAccountOf(alice, 1_000, 1_000); // 1_100 balance with yield without fee.
        assertEq(mYieldFee.accruedYieldOf(alice), 79); // Should be 100 - 100 * 20% = 80 but it rounds down.

        // Another 10% index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(mYieldFee.currentIndex(), 1_164738254609);

        assertEq(mYieldFee.accruedYieldOf(alice), 164); // Would be 210 - 210 * 20% = 168 if the index wasn't compounding.

        mYieldFee.setAccountOf(alice, 1_000, 1_500); // 1_885 balance with yield without fee.

        // Present balance at fee-adjusted index (1_747) - balance (1_000)
        assertEq(mYieldFee.accruedYieldOf(alice), 747);
    }

    /* ============ balanceOf ============ */

    function test_balanceOf() external {
        uint240 balance = 1_000e6;
        mYieldFee.setAccountOf(alice, balance, 800e6);

        assertEq(mYieldFee.balanceOf(alice), balance);
    }

    /* ============ balanceWithYieldOf ============ */

    function test_balanceWithYieldOf() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        mYieldFee.setAccountOf(alice, 500e6, 500e6); // 550 balance with yield without fee
        assertEq(mYieldFee.balanceWithYieldOf(alice), 500e6 + 39_615199); // Should be 540 but it rounds down

        mYieldFee.setAccountOf(alice, 1_000e6, 1_000e6); // 1_100 balance with yield without fee
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 79_230399); // Should be 1_080 but it rounds down

        // Another 10% index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(mYieldFee.currentIndex(), 1_164738254609);

        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 164_738254); // Would be 1_168 if the index wasn't compounding

        mYieldFee.setAccountOf(alice, 1_000e6, 1_500e6); // 1_885 balance with yield without fee.

        // Present balance at fee-adjusted index (1_747)
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 747_107381);
    }

    /* ============ principalOf ============ */

    function test_principalOf() external {
        uint112 principal = 800e6;
        mYieldFee.setAccountOf(alice, 1_000e6, principal);

        assertEq(mYieldFee.principalOf(alice), principal);
    }

    /* ============ projectedTotalSupply ============ */

    // TODO: add integration test
    function test_projectedTotalSupply() external {
        uint256 totalSupply = 1_000e6;

        mToken.setBalanceOf(address(mYieldFee), totalSupply);
        assertEq(mYieldFee.projectedTotalSupply(), totalSupply);
    }

    /* ============ totalAccruedYield ============ */

    function test_totalAccruedYield() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        // 550 balance with yield without fee
        mYieldFee.setTotalSupply(500e6);
        mYieldFee.setTotalPrincipal(500e6);

        assertEq(mYieldFee.totalAccruedYield(), 39_615199); // Should be 40 but it rounds down

        // 1_100 balance with yield without fee.
        mYieldFee.setTotalSupply(1_000e6);
        mYieldFee.setTotalPrincipal(1_000e6);
        assertEq(mYieldFee.totalAccruedYield(), 79_230399); // Should be 80 but it rounds down

        // Another 10% index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(mYieldFee.currentIndex(), 1_164738254609);

        assertEq(mYieldFee.totalAccruedYield(), 164_738254); // Should be 168 if the index wasn't compounding

        // 1_885 balance with yield without fee
        mYieldFee.setTotalSupply(1_000e6);
        mYieldFee.setTotalPrincipal(1_500e6);

        // Present balance at fee-adjusted index (1_747) - balance (1_000)
        assertEq(mYieldFee.totalAccruedYield(), 747_107381);
    }

    /* ============ totalAccruedYieldFee ============ */

    // TODO: add fuzz test
    function test_totalAccruedYieldFee() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        // 550 balance with yield without fee
        mYieldFee.setTotalSupply(500);
        mYieldFee.setTotalPrincipal(500);
        assertEq(mYieldFee.totalAccruedYield(), 39); // Should be 50 - 50 * 20% = 40 but it rounds down

        mToken.setBalanceOf(address(mYieldFee), 550);
        assertEq(mYieldFee.totalAccruedYieldFee(), 11);
        assertEq(mYieldFee.totalAccruedYield() + mYieldFee.totalAccruedYieldFee(), 50);

        // 1_100 balance with yield without fee.
        mYieldFee.setTotalSupply(1_000);
        mYieldFee.setTotalPrincipal(1_000);
        assertEq(mYieldFee.totalAccruedYield(), 79); // Should be 100 - 100 * 20% = 80 but it rounds down

        mToken.setBalanceOf(address(mYieldFee), 1_100);
        assertEq(mYieldFee.totalAccruedYieldFee(), 21);
        assertEq(mYieldFee.totalAccruedYield() + mYieldFee.totalAccruedYieldFee(), 100);

        // Another 10% index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(mYieldFee.currentIndex(), 1_164738254609);

        assertEq(mYieldFee.totalAccruedYield(), 164); // Should be 210 - 210 * 20% = 168 if the index wasn't compounding

        mToken.setBalanceOf(address(mYieldFee), 1_210);
        assertEq(mYieldFee.totalAccruedYieldFee(), 46);
        assertEq(mYieldFee.totalAccruedYield() + mYieldFee.totalAccruedYieldFee(), 210);

        // 1_885 balance with yield without fee
        mYieldFee.setTotalSupply(1_000);
        mYieldFee.setTotalPrincipal(1_500);

        // Present balance at fee-adjusted index (1_747) - balance (1_000)
        assertEq(mYieldFee.totalAccruedYield(), 747);

        mToken.setBalanceOf(address(mYieldFee), 1_885);
        assertEq(mYieldFee.totalAccruedYieldFee(), 138);
        assertEq(mYieldFee.totalAccruedYield() + mYieldFee.totalAccruedYieldFee(), 885);
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
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        mToken.setBalanceOf(alice, 1_002);
        mToken.setBalanceOf(address(mYieldFee), 1_100);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 21
        mYieldFee.setAccountOf(alice, 1_000, 1_000);

        assertEq(mYieldFee.principalOf(alice), 1_000);
        assertEq(mYieldFee.balanceOf(alice), 1_000);
        assertEq(mYieldFee.accruedYieldOf(alice), 79);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 79);
        assertEq(mYieldFee.totalPrincipal(), 1_000);
        assertEq(mYieldFee.totalSupply(), 1_000);
        assertEq(mYieldFee.totalAccruedYield(), 79); // Should be 80 but it rounds down
        assertEq(mYieldFee.projectedTotalSupply(), 1_100);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 999);

        vm.prank(alice);
        mYieldFee.wrap(alice, 999);

        // Index hasn't changed, so yield remains the same.
        assertEq(mYieldFee.principalOf(alice), 1_000 + 925);
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999);
        assertEq(mYieldFee.accruedYieldOf(alice), 78); // 79 - 1 rounds down
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 78);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 925 + 1); // Added principal is rounded up
        assertEq(mYieldFee.totalSupply(), 1_000 + 999);
        assertEq(mYieldFee.totalAccruedYield(), 79);
        assertEq(mYieldFee.projectedTotalSupply(), 2_099);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1);

        vm.prank(alice);
        mYieldFee.wrap(alice, 1);

        assertEq(mYieldFee.principalOf(alice), 1_000 + 925); // No change due to principal round down on wrap.
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999 + 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 78 - 1);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 78);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 925 + 1 + 1);
        assertEq(mYieldFee.totalSupply(), 1_000 + 999 + 1);
        assertEq(mYieldFee.totalAccruedYield(), 79);
        assertEq(mYieldFee.projectedTotalSupply(), 2_099 + 1); // rounds up

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 2);

        vm.prank(alice);
        mYieldFee.wrap(alice, 2);

        assertEq(mYieldFee.principalOf(alice), 1_000 + 925 + 1); // Rounds down on wrap.
        assertEq(mYieldFee.balanceOf(alice), 1_000 + 999 + 1 + 2);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 999 + 78 + 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 78 - 1 - 1);
        assertEq(mYieldFee.totalPrincipal(), 1_000 + 925 + 1 + 1 + 2);
        assertEq(mYieldFee.totalSupply(), 1_000 + 999 + 1 + 2);
        assertEq(mYieldFee.totalAccruedYield(), 79);
        assertEq(mYieldFee.projectedTotalSupply(), 2_099 + 1 + 2);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mYieldFee)), 2_099 + 1 + 2);
    }

    // //     function testFuzz_wrap(
    // //         bool earningEnabled_,
    // //         uint240 balanceWithYield_,
    // //         uint240 balance_,
    // //         uint240 wrapAmount_,
    // //         uint128 currentMIndex_,
    // //         uint128 enableMIndex_,
    // //         uint128 disableIndex_
    // //     ) external {
    // //         (currentMIndex_, enableMIndex_, disableIndex_) = _getFuzzedIndices(
    // //             currentMIndex_,
    // //             enableMIndex_,
    // //             disableIndex_
    // //         );
    // //
    // //         uint128 currentIndex = mYieldFee.currentIndex();
    // //
    // //         _setupIndices(earningEnabled_, currentMIndex_, enableMIndex_, disableIndex_);
    // //         (balanceWithYield_, balance_) = _getFuzzedBalances(
    // //             currentIndex,
    // //             balanceWithYield_,
    // //             balance_,
    // //             _getMaxAmount(currentIndex)
    // //         );
    // //
    // //         uint112 alicePrincipal = _setupAccount(alice, balanceWithYield_, balance_);
    // //
    // //         wrapAmount_ = uint240(bound(wrapAmount_, 0, _getMaxAmount(currentIndex) - balanceWithYield_));
    // //
    // //         mToken.setBalanceOf(alice, wrapAmount_);
    // //
    // //         if (wrapAmount_ == 0) {
    // //             vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, (0)));
    // //         } else {
    // //             vm.expectEmit();
    // //             emit IERC20.Transfer(address(0), alice, wrapAmount_);
    // //         }
    // //
    // //         vm.startPrank(alice);
    // //         mYieldFee.wrap(alice, wrapAmount_);
    // //
    // //         if (wrapAmount_ == 0) return;
    // //
    // //         uint240 aliceBalance = balance_ + wrapAmount_;
    // //         alicePrincipal += IndexingMath.getPrincipalAmountRoundedDown(wrapAmount_, currentIndex);
    // //
    // //         uint240 aliceBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(alicePrincipal, currentIndex);
    // //         uint240 aliceYield = !earningEnabled_ || (aliceBalanceWithYield <= aliceBalance)
    // //             ? 0
    // //             : aliceBalanceWithYield - aliceBalance;
    // //
    // //         uint16 yieldFeeRate = mYieldFee.yieldFeeRate();
    // //         uint240 yieldFee = aliceYield == 0 ? 0 : (aliceYield * yieldFeeRate) / HUNDRED_PERCENT;
    // //
    // //         assertEq(mYieldFee.balanceOf(alice), aliceBalance);
    // //         assertEq(mYieldFee.balanceOf(alice), mYieldFee.totalSupply());
    // //
    // //         assertApproxEqAbs(mYieldFee.principalOf(alice), mYieldFee.totalPrincipal(), 1); // May round down on wrap.
    // //
    // //         assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + aliceYield - yieldFee);
    // //         assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + mYieldFee.accruedYieldOf(alice));
    // //
    // //         // Principal is rounded up when adding to total principal.
    // //         // And projected supply is rounded up when converting total principal to a present amount.
    // //         // TODO: why is the rounding error so high?
    // //         assertApproxEqAbs(mYieldFee.balanceWithYieldOf(alice) + yieldFee, mYieldFee.projectedTotalSupply(), 81);
    // //     }
    //
    // /* ============ unwrap ============ */
    //
    // function test_unwrap_invalidAmount() external {
    //     vm.expectRevert(UIntMath.InvalidUInt240.selector);
    //
    //     vm.prank(alice);
    //     mYieldFee.unwrap(alice, uint256(type(uint240).max) + 1);
    // }
    //
    // function test_unwrap_insufficientAmount() external {
    //     vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));
    //
    //     vm.prank(alice);
    //     mYieldFee.unwrap(alice, 0);
    // }
    //
    // function test_unwrap_insufficientBalance() external {
    //     mToken.setCurrentIndex(1_125000000000);
    //
    //     mYieldFee.setAccountOf(alice, 999, 909);
    //
    //     vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));
    //
    //     vm.prank(alice);
    //     mYieldFee.unwrap(alice, 1_000);
    // }
    //
    // function test_unwrap() external {
    //     // 10% index growth
    //     mToken.setLatestIndex(1_100000000000);
    //     mYieldFee.setEnableLatestMIndex(1_100000000000);
    //     mToken.setLatestUpdateTimestamp(block.timestamp);
    //
    //     vm.warp(startTimestamp + 30_057_038);
    //     assertEq(mYieldFee.currentIndex(), 1_079230399224);
    //
    //     mToken.setBalanceOf(address(mYieldFee), 1_100);
    //
    //     mYieldFee.setTotalPrincipal(1_000);
    //     mYieldFee.setTotalSupply(1_000);
    //
    //     // Total supply + yield: 1_100
    //     // Alice balance with yield: 1_079
    //     // Fee: 21
    //     mYieldFee.setAccountOf(alice, 1_000, 1_000); // 1_100 balance with yield without fee
    //
    //     assertEq(mYieldFee.principalOf(alice), 1_000);
    //     assertEq(mYieldFee.balanceOf(alice), 1_000);
    //     assertEq(mYieldFee.accruedYieldOf(alice), 79);
    //     assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 79);
    //     assertEq(mYieldFee.totalPrincipal(), 1_000);
    //     assertEq(mYieldFee.totalSupply(), 1_000);
    //     assertEq(mYieldFee.totalAccruedYield(), 79); // Should be 80 but it rounds down
    //     assertEq(mYieldFee.projectedTotalSupply(), 1_100);
    //
    //     vm.expectEmit();
    //     emit IERC20.Transfer(alice, address(0), 1);
    //
    //     vm.prank(alice);
    //     mYieldFee.unwrap(alice, 1);
    //
    //     assertEq(mYieldFee.principalOf(alice), 1_000 - 1);
    //     assertEq(mYieldFee.balanceOf(alice), 1_000 - 1);
    //     assertEq(mYieldFee.accruedYieldOf(alice), 79);
    //     assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000 + 79 - 1);
    //     assertEq(mYieldFee.totalPrincipal(), 1_000); // No change due to principal round up on unwrap
    //     assertEq(mYieldFee.totalSupply(), 1_000 - 1);
    //     assertEq(mYieldFee.totalAccruedYield(), 79 + 1);
    //     assertEq(mYieldFee.projectedTotalSupply(), 1_100 - 1);
    //
    //     vm.expectEmit();
    //     emit IERC20.Transfer(alice, address(0), 499);
    //
    //     vm.prank(alice);
    //     mYieldFee.unwrap(alice, 499);
    //
    //     assertEq(mYieldFee.principalOf(alice), 1_000 - 1 - 463);
    //     assertEq(mYieldFee.balanceOf(alice), 1_000 - 1 - 499);
    //     assertEq(mYieldFee.accruedYieldOf(alice), 79 - 1);
    //     assertEq(mYieldFee.totalPrincipal(), 1_000 - 1 - 463 + 2);
    //     assertEq(mYieldFee.totalSupply(), 1_000 - 1 - 499);
    //     assertEq(mYieldFee.totalAccruedYield(), 79 + 1);
    //     assertEq(mYieldFee.projectedTotalSupply(), 1_100 - 499 - 1);
    //
    //     vm.expectEmit();
    //     emit IERC20.Transfer(alice, address(0), 500);
    //
    //     vm.prank(alice);
    //     mYieldFee.unwrap(alice, 500);
    //
    //     assertEq(mYieldFee.principalOf(alice), 1_000 - 1 - 463 - 464); // 72
    //     assertEq(mYieldFee.balanceOf(alice), 1_000 - 1 - 499 - 500); // 0
    //     assertEq(mYieldFee.accruedYieldOf(alice), 79 - 1 - 1);
    //     assertEq(mYieldFee.totalPrincipal(), 1_000 - 1 - 463 - 464 + 3);
    //     assertEq(mYieldFee.totalSupply(), 1_000 - 1 - 499 - 500); // 0
    //     assertEq(mYieldFee.totalAccruedYield(), 79 + 1);
    //     assertEq(mYieldFee.projectedTotalSupply(), 1_100 - 499 - 500 - 1); // 100
    //
    //     assertEq(mToken.balanceOf(alice), 1000);
    //     assertEq(mToken.balanceOf(address(mYieldFee)), 100);
    // }
    //
    // //     function testFuzz_unwrap(
    // //         bool earningEnabled_,
    // //         uint240 balanceWithYield_,
    // //         uint240 balance_,
    // //         uint240 unwrapAmount_,
    // //         uint128 currentMIndex_,
    // //         uint128 enableMIndex_,
    // //         uint128 disableIndex_
    // //     ) external {
    // //         (currentMIndex_, enableMIndex_, disableIndex_) = _getFuzzedIndices(
    // //             currentMIndex_,
    // //             enableMIndex_,
    // //             disableIndex_
    // //         );
    // //
    // //         _setupIndices(earningEnabled_, currentMIndex_, enableMIndex_, disableIndex_);
    // //
    // //         (balanceWithYield_, balance_) = _getFuzzedBalances(
    // //             currentMIndex_,
    // //             balanceWithYield_,
    // //             balance_,
    // //             _getMaxAmount(mYieldFee.currentIndex())
    // //         );
    // //
    // //         uint112 alicePrincipal = _setupAccount(alice, balanceWithYield_, balance_);
    // //
    // //         mToken.setBalanceOf(address(mYieldFee), balance_);
    // //
    // //         unwrapAmount_ = uint240(bound(unwrapAmount_, 0, _getMaxAmount(mYieldFee.currentIndex()) - balanceWithYield_));
    // //
    // //         if (unwrapAmount_ == 0) {
    // //             vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, (0)));
    // //         } else if (unwrapAmount_ > balance_) {
    // //             vm.expectRevert(
    // //                 abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, balance_, unwrapAmount_)
    // //             );
    // //         } else {
    // //             vm.expectEmit();
    // //             emit IERC20.Transfer(alice, address(0), unwrapAmount_);
    // //         }
    // //
    // //         vm.startPrank(alice);
    // //         mYieldFee.unwrap(alice, unwrapAmount_);
    // //
    // //         if ((unwrapAmount_ == 0) || (unwrapAmount_ > balance_)) return;
    // //
    // //         uint240 aliceBalance = balance_ - unwrapAmount_;
    // //         uint112 unwrapPrincipalUp = IndexingMath.getPrincipalAmountRoundedUp(unwrapAmount_, mYieldFee.currentIndex());
    // //         alicePrincipal = unwrapPrincipalUp > alicePrincipal ? 0 : alicePrincipal - unwrapPrincipalUp;
    // //
    // //         uint240 aliceBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(
    // //             alicePrincipal,
    // //             mYieldFee.currentIndex()
    // //         );
    // //
    // //         uint240 aliceYield = (aliceBalanceWithYield <= aliceBalance) ? 0 : aliceBalanceWithYield - aliceBalance;
    // //
    // //         uint16 yieldFeeRate = mYieldFee.yieldFeeRate();
    // //         uint240 yieldFee = aliceYield == 0 ? 0 : (aliceYield * yieldFeeRate) / HUNDRED_PERCENT;
    // //
    // //         assertEq(mYieldFee.balanceOf(alice), aliceBalance);
    // //         assertEq(mYieldFee.balanceOf(alice), mYieldFee.totalSupply());
    // //
    // //         assertApproxEqAbs(mYieldFee.principalOf(alice), mYieldFee.totalPrincipal(), 1); // May round up on unwrap.
    // //
    // //         assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + aliceYield - yieldFee);
    // //         assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance + mYieldFee.accruedYieldOf(alice));
    // //
    // //         // Principal is rounded down when subtracting from total principal.
    // //         // And projected supply is rounded up when converting total principal to a present amount.
    // //         // TODO: why is the rounding error so high?
    // //         assertApproxEqAbs(mYieldFee.balanceWithYieldOf(alice) + yieldFee, mYieldFee.projectedTotalSupply(), 94);
    // //     }

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

    // TODO: add integration test
    function test_transfer() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        mToken.setBalanceOf(alice, 1_002);
        mToken.setBalanceOf(address(mYieldFee), 1_500);

        mYieldFee.setTotalPrincipal(1_500);
        mYieldFee.setTotalSupply(1_500);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 21
        mYieldFee.setAccountOf(alice, 1_000, 1_000);

        // Bob balance with yield: 539
        // Balance: 500
        // Yield: 50
        // Fee: 11
        mYieldFee.setAccountOf(bob, 500, 500);

        assertEq(mYieldFee.accruedYieldOf(alice), 79);
        assertEq(mYieldFee.accruedYieldOf(bob), 39);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, 500);

        vm.prank(alice);
        mYieldFee.transfer(bob, 500);

        assertEq(mYieldFee.principalOf(alice), 536);
        assertEq(mYieldFee.balanceOf(alice), 500);
        assertEq(mYieldFee.accruedYieldOf(alice), 79 - 1);

        assertEq(mYieldFee.principalOf(bob), 963);
        assertEq(mYieldFee.balanceOf(bob), 1_000);
        assertEq(mYieldFee.accruedYieldOf(bob), 40 - 1); // Rounds principal down on transfer.

        assertEq(mYieldFee.totalSupply(), 1_500);

        // Principal is rounded up when adding and rounded down when subtracting.
        assertEq(mYieldFee.totalPrincipal(), 1_501);
        assertEq(mYieldFee.totalAccruedYield(), 79 + 39 + 1);
    }

    function test_transfer_toSelf() external {
        mYieldFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(mYieldFee.currentIndex(), 1_079230399224);

        mYieldFee.setTotalPrincipal(1_000);
        mYieldFee.setTotalSupply(1_000);
        mToken.setBalanceOf(address(mYieldFee), 1_125);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 21
        mYieldFee.setAccountOf(alice, 1_000, 1_000);

        assertEq(mYieldFee.balanceOf(alice), 1_000);
        assertEq(mYieldFee.accruedYieldOf(alice), 79);

        vm.expectEmit();
        emit IERC20.Transfer(alice, alice, 500);

        vm.prank(alice);
        mYieldFee.transfer(alice, 500);

        assertEq(mYieldFee.principalOf(alice), 1_000);
        assertEq(mYieldFee.balanceOf(alice), 1_000);
        assertEq(mYieldFee.accruedYieldOf(alice), 79);

        assertEq(mYieldFee.totalPrincipal(), 1_000);
        assertEq(mYieldFee.totalSupply(), 1_000);
        assertEq(mYieldFee.totalAccruedYield(), 79);
        assertEq(mYieldFee.projectedTotalSupply(), 1_125);
    }

    //     function testFuzz_transfer(
    //         bool earningEnabled_,
    //         uint240 aliceBalanceWithYield_,
    //         uint240 aliceBalance_,
    //         uint240 bobBalanceWithYield_,
    //         uint240 bobBalance_,
    //         uint128 currentMIndex_,
    //         uint128 enableMIndex_,
    //         uint128 disableIndex_,
    //         uint240 amount_
    //     ) external {
    //         (currentMIndex_, enableMIndex_, disableIndex_) = _getFuzzedIndices(
    //             currentMIndex_,
    //             enableMIndex_,
    //             disableIndex_
    //         );
    //
    //         _setupIndices(earningEnabled_, currentMIndex_, enableMIndex_, disableIndex_);
    //
    //         (aliceBalanceWithYield_, aliceBalance_) = _getFuzzedBalances(
    //             mYieldFee.currentIndex(),
    //             aliceBalanceWithYield_,
    //             aliceBalance_,
    //             _getMaxAmount(mYieldFee.currentIndex())
    //         );
    //
    //         uint112 alicePrincipal = _setupAccount(alice, aliceBalanceWithYield_, aliceBalance_);
    //         (bobBalanceWithYield_, bobBalance_) = _getFuzzedBalances(
    //             mYieldFee.currentIndex(),
    //             bobBalanceWithYield_,
    //             bobBalance_,
    //             _getMaxAmount(mYieldFee.currentIndex()) - aliceBalanceWithYield_
    //         );
    //
    //         uint112 bobPrincipal = _setupAccount(bob, bobBalanceWithYield_, bobBalance_);
    //
    //         amount_ = uint240(bound(amount_, 0, _getMaxAmount(mYieldFee.currentIndex()) - bobBalanceWithYield_));
    //
    //         if (amount_ > aliceBalance_) {
    //             vm.expectRevert(
    //                 abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, aliceBalance_, amount_)
    //             );
    //         } else {
    //             vm.expectEmit();
    //             emit IERC20.Transfer(alice, bob, amount_);
    //         }
    //
    //         vm.prank(alice);
    //         mYieldFee.transfer(bob, amount_);
    //
    //         if (amount_ > aliceBalance_) return;
    //
    //         assertEq(mYieldFee.balanceOf(alice), aliceBalance_ - amount_);
    //         assertEq(mYieldFee.balanceOf(bob), bobBalance_ + amount_);
    //
    //         aliceBalance_ -= amount_;
    //         alicePrincipal -= IndexingMath.getPrincipalAmountRoundedUp(amount_, mYieldFee.currentIndex()) > alicePrincipal
    //             ? 0
    //             : IndexingMath.getPrincipalAmountRoundedUp(amount_, mYieldFee.currentIndex());
    //
    //         (uint240 aliceBalanceWithYield, uint240 aliceYield) = _getBalanceWithYield(
    //             aliceBalance_,
    //             alicePrincipal,
    //             mYieldFee.currentIndex()
    //         );
    //
    //         // TODO: why is there a rounding issue while aliceBalance_ + mYieldFee.accruedYieldOf(alice) is correct?
    //         assertApproxEqAbs(
    //             mYieldFee.balanceWithYieldOf(alice),
    //             aliceBalanceWithYield - _getYieldFee(aliceYield, mYieldFee.yieldFeeRate()),
    //             50
    //         );
    //
    //         assertEq(mYieldFee.balanceWithYieldOf(alice), aliceBalance_ + mYieldFee.accruedYieldOf(alice));
    //
    //         bobBalance_ += amount_;
    //         bobPrincipal += IndexingMath.getPrincipalAmountRoundedDown(amount_, mYieldFee.currentIndex());
    //
    //         (uint240 bobBalanceWithYield, uint240 bobYield) = _getBalanceWithYield(
    //             bobBalance_,
    //             bobPrincipal,
    //             mYieldFee.currentIndex()
    //         );
    //
    //         // TODO: why is there a rounding issue while bobBalance_ + mYieldFee.accruedYieldOf(bob) is correct?
    //         assertApproxEqAbs(
    //             mYieldFee.balanceWithYieldOf(bob),
    //             bobBalanceWithYield - _getYieldFee(bobYield, mYieldFee.yieldFeeRate()),
    //             77
    //         );
    //
    //         assertEq(mYieldFee.balanceWithYieldOf(bob), bobBalance_ + mYieldFee.accruedYieldOf(bob));
    //
    //         assertEq(mYieldFee.totalSupply(), aliceBalance_ + bobBalance_);
    //         assertEq(mYieldFee.totalSupply(), mYieldFee.balanceOf(alice) + mYieldFee.balanceOf(bob));
    //
    //         // Principal added or removed from totalPrincipal is rounded up when adding and rounded down when subtracting.
    //         assertApproxEqAbs(mYieldFee.totalPrincipal(), alicePrincipal + bobPrincipal, 2);
    //         assertApproxEqAbs(mYieldFee.totalPrincipal(), mYieldFee.principalOf(alice) + mYieldFee.principalOf(bob), 2);
    //
    //         // TODO: why is there a rounding issue?
    //         assertApproxEqAbs(
    //             mYieldFee.projectedTotalSupply(),
    //             mYieldFee.balanceWithYieldOf(alice) +
    //                 _getYieldFee(aliceYield, mYieldFee.yieldFeeRate()) +
    //                 mYieldFee.balanceWithYieldOf(bob) +
    //                 _getYieldFee(bobYield, mYieldFee.yieldFeeRate()),
    //             193
    //         );
    //     }
    //
    //     /* ============ Fuzz Utils ============ */
    //
    //     function _setupAccount(
    //         address account_,
    //         uint240 balanceWithYield_,
    //         uint240 balance_
    //     ) internal returns (uint112 principal_) {
    //         principal_ = IndexingMath.getPrincipalAmountRoundedDown(balanceWithYield_, mYieldFee.currentIndex());
    //
    //         mYieldFee.setAccountOf(account_, balance_, principal_, mYieldFee.currentIndex());
    //         mYieldFee.setTotalPrincipal(mYieldFee.totalPrincipal() + principal_);
    //         mYieldFee.setTotalSupply(mYieldFee.totalSupply() + balance_);
    //     }
    //
    //     function _setupIndices(
    //         bool earningEnabled_,
    //         uint128 currentMIndex_,
    //         uint128 enableMIndex_,
    //         uint128 disableIndex_
    //     ) internal {
    //         mToken.setCurrentIndex(currentMIndex_);
    //         mYieldFee.setDisableIndex(disableIndex_);
    //
    //         if (earningEnabled_) {
    //             mToken.setIsEarning(address(mYieldFee), true);
    //             mYieldFee.setEnableMIndex(enableMIndex_);
    //         }
    //     }
}
