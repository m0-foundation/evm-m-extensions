// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";

import { MYieldFee } from "../../src/MYieldFee.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract MYieldFeeIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    function setUp() public override {
        super.setUp();

        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        _fundAccounts();

        mYieldFee = new MYieldFee(
            NAME,
            SYMBOL,
            address(mToken),
            YIELD_FEE_RATE,
            yieldFeeRecipient,
            admin,
            yieldFeeManager
        );
    }

    function test_integration_constants() external view {
        assertEq(mYieldFee.name(), NAME);
        assertEq(mYieldFee.symbol(), SYMBOL);
        assertEq(mYieldFee.decimals(), 6);
        assertEq(mYieldFee.mToken(), address(mToken));
        assertEq(mYieldFee.HUNDRED_PERCENT(), 10_000);
        assertEq(mYieldFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(mYieldFee.yieldFeeRate(), YIELD_FEE_RATE);
        assertEq(mYieldFee.yieldFeeRecipient(), yieldFeeRecipient);
        assertTrue(mYieldFee.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mYieldFee.hasRole(YIELD_FEE_MANAGER_ROLE, yieldFeeManager));
    }

    function test_yieldAccumulationAndClaim() external {
        uint256 amount = 10e6;

        // Enable earning for the contract
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        // Check the initial earning state and index
        assertEq(mToken.isEarning(address(mYieldFee)), true);
        assertEq(mYieldFee.currentIndex(), EXP_SCALED_ONE);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        // wrap from non-earner account
        _wrap(address(mYieldFee), alice, alice, amount);

        // Check balances of MYieldFee and Alice after wrapping
        assertEq(mYieldFee.balanceOf(alice), amount); // user receives exact amount
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), amount, 2); // rounds down

        // Fast forward 10 days in the future to generate yield
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // yield accrual
        uint256 totalYield = 11375;
        uint256 yieldFee = _getYieldFee(totalYield, YIELD_FEE_RATE);

        assertEq(mYieldFee.totalAccruedYield(), totalYield - yieldFee);
        assertApproxEqAbs(mYieldFee.totalAccruedYieldFee(), yieldFee, 1); // May round up

        // transfers do not affect yield (except for rounding error)
        vm.prank(alice);
        mYieldFee.transfer(bob, amount / 2);

        assertEq(mYieldFee.balanceOf(bob), amount / 2);
        assertEq(mYieldFee.balanceOf(alice), amount / 2);

        // yield accrual
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 1); // May round up
        assertApproxEqAbs(mYieldFee.totalAccruedYieldFee(), yieldFee, 1); // May round down

        // unwraps
        _unwrap(address(mYieldFee), alice, alice, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 1); // May round up
        assertApproxEqAbs(mYieldFee.totalAccruedYieldFee(), yieldFee, 3); // May round down

        _unwrap(address(mYieldFee), bob, bob, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 2); // May round up
        assertApproxEqAbs(mYieldFee.totalAccruedYieldFee(), yieldFee, 5); // May round down

        assertEq(mYieldFee.balanceOf(bob), 0);
        assertEq(mYieldFee.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(bob), amount + amount / 2);
        assertEq(mToken.balanceOf(alice), amount / 2);

        assertEq(mToken.balanceOf(yieldFeeRecipient), 0);

        // claim yield
        uint256 aliceYield = mYieldFee.claimYieldFor(alice);
        yieldFee = mYieldFee.claimYieldFee();
        mYieldFee.claimYieldFor(bob);

        assertEq(mYieldFee.balanceOf(alice), aliceYield);
        assertEq(mYieldFee.balanceOf(bob), 0); // Bob's yield is 0 cause he received and unwrapped in the same block

        assertEq(mYieldFee.balanceOf(yieldFeeRecipient), yieldFee);
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), aliceYield + yieldFee, 5); // May round down
        assertEq(mYieldFee.totalSupply(), aliceYield + yieldFee);

        // Due to principal round down for account and totalPrincipal round up
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), 0, 5);
        assertEq(mYieldFee.totalAccruedYieldFee(), 0);

        // Alice and yield fee recipient unwraps
        _unwrap(address(mYieldFee), alice, alice, aliceYield);
        _unwrap(address(mYieldFee), yieldFeeRecipient, yieldFeeRecipient, yieldFee);

        assertEq(mYieldFee.accruedYieldOf(alice), 0);
        assertEq(mYieldFee.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), amount / 2 + aliceYield);

        assertEq(mYieldFee.accruedYieldOf(yieldFeeRecipient), 0);
        assertEq(mYieldFee.balanceOf(yieldFeeRecipient), 0);
        assertEq(mToken.balanceOf(yieldFeeRecipient), yieldFee);

        // Some excess due to rounding may be left in the extension
        // TODO: could be avoided by transferring M instead of the extension token to the yield recipient
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), 4, 1);

        // wrap from earner account
        _addToList(EARNERS_LIST, bob);

        vm.prank(bob);
        mToken.startEarning();

        _wrap(address(mYieldFee), bob, bob, amount);

        // Check balances of MYieldFee and Bob after wrapping
        assertEq(mYieldFee.balanceOf(bob), amount);
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), amount, 4); // Account for the excess

        // Disable earning for the contract
        _removeFomList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.disableEarning();

        assertFalse(mYieldFee.isEarningEnabled());

        // Fast forward 10 days in the future
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // No yield should accrue
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), 0, 4); // Account for the excess

        // Re-enable earning for the contract
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        // Yield should accrue again
        vm.warp(vm.getBlockTimestamp() + 10 days);

        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 1); // May round down
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), amount + totalYield, 4); // Account for the excess
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_notApprovedEarner() external {
        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.NotApprovedEarner.selector));
        mYieldFee.enableEarning();
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_approvedEarner() external {
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.IsApprovedEarner.selector));
        mYieldFee.disableEarning();
    }

    /* ============ _wrap ============ */

    function test_wrapWithPermits() external {
        assertEq(mToken.balanceOf(alice), 10e6);

        _wrapWithPermitVRS(address(mYieldFee), alice, aliceKey, alice, 5e6, 0, block.timestamp);

        assertEq(mYieldFee.balanceOf(alice), 5e6);
        assertEq(mToken.balanceOf(alice), 5e6);

        _wrapWithPermitVRS(address(mYieldFee), alice, aliceKey, alice, 5e6, 1, block.timestamp);

        assertEq(mYieldFee.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(alice), 0);
    }
}
