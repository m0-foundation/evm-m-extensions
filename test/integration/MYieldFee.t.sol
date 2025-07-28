// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";

import { MYieldFeeHarness } from "../harness/MYieldFeeHarness.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract MYieldFeeIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    function setUp() public override {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_482_175);

        super.setUp();

        _fundAccounts();

        mYieldFee = MYieldFeeHarness(
            Upgrades.deployTransparentProxy(
                "MYieldFeeHarness.sol:MYieldFeeHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldFeeHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    YIELD_FEE_RATE,
                    feeRecipient,
                    admin,
                    feeManager,
                    claimRecipientManager
                ),
                mExtensionDeployOptions
            )
        );
    }

    function test_integration_constants() external view {
        assertEq(mYieldFee.name(), NAME);
        assertEq(mYieldFee.symbol(), SYMBOL);
        assertEq(mYieldFee.decimals(), 6);
        assertEq(mYieldFee.mToken(), address(mToken));
        assertEq(mYieldFee.ONE_HUNDRED_PERCENT(), 10_000);
        assertEq(mYieldFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(mYieldFee.feeRate(), YIELD_FEE_RATE);
        assertEq(mYieldFee.feeRecipient(), feeRecipient);
        assertTrue(mYieldFee.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mYieldFee.hasRole(FEE_MANAGER_ROLE, feeManager));
    }

    /* ============ index ============ */

    function test_indexGrowth() external {
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        // The M_EARNER_RATE is 415 bps. To achieve a 10% growth on the M token index,
        // we need to solve for t in: 1.1 = e^(rate * t)
        // t = ln(1.1) / rate_per_second
        // t = 0.0953101798 / (0.0415 / 31536000) = 72,426,135 seconds
        uint256 timeDelta = 72_426_135;

        assertEq(mToken.currentIndex(), 1_043072100803);
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        // The MYieldFee earner rate is 332 bps (415 * (1 - 0.20))
        // So its index will grow by e^(0.0332/31536000 * 72426135) = 1.07923
        // The expected index is 1 * 1.079229873640 = 1_079229873640
        uint128 expectedMYieldFeeIndex = 1_079229873640;

        assertEq(mYieldFee.currentIndex(), expectedMYieldFeeIndex);
        assertEq(mToken.currentIndex(), 1_147378684081);

        // Update the index to set the new baseline for the next growth period
        mYieldFee.updateIndex();
        assertEq(mYieldFee.latestIndex(), expectedMYieldFeeIndex);

        // Warp forward by the same delta again to simulate another 10% M token growth
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        uint128 expectedSecondMYieldFeeIndex = 1_164737120157;

        assertEq(mYieldFee.currentIndex(), expectedSecondMYieldFeeIndex);
        assertEq(mToken.currentIndex(), 1_262115863007);
    }

    /* ============ yield accrual ============ */

    function test_yieldAccumulationAndClaim() external {
        uint256 amount = 10e6;

        // Enable earning for the contract
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        // Check the initial earning state and index
        assertEq(mToken.isEarning(address(mYieldFee)), true);
        assertEq(mYieldFee.currentIndex(), EXP_SCALED_ONE);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        // swap M to extension from non-earner account
        _swapInM(address(mYieldFee), alice, alice, amount);

        // Check balances of MYieldFee and Alice after wrapping
        assertEq(mYieldFee.balanceOf(alice), amount); // user receives exact amount
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), amount, 2); // rounds down

        // Fast forward 10 days in the future to generate yield
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // yield accrual
        uint256 totalYield = 11375;
        uint256 yieldFee = _getYieldFee(totalYield, YIELD_FEE_RATE);

        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 1); // May round down
        assertEq(mYieldFee.totalAccruedFee(), yieldFee);

        // transfers do not affect yield (except for rounding error)
        vm.prank(alice);
        mYieldFee.transfer(bob, amount / 2);

        assertEq(mYieldFee.balanceOf(bob), amount / 2);
        assertEq(mYieldFee.balanceOf(alice), amount / 2);

        // yield accrual
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 1); // May round down
        assertEq(mYieldFee.totalAccruedFee(), yieldFee);

        // unwraps
        _swapMOut(address(mYieldFee), alice, alice, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 1); // May round down
        assertApproxEqAbs(mYieldFee.totalAccruedFee(), yieldFee, 1); // May round down

        _swapMOut(address(mYieldFee), bob, bob, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 1); // May round down
        assertApproxEqAbs(mYieldFee.totalAccruedFee(), yieldFee, 2); // May round down

        assertEq(mYieldFee.balanceOf(bob), 0);
        assertEq(mYieldFee.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(bob), amount + amount / 2);
        assertEq(mToken.balanceOf(alice), amount / 2);

        assertEq(mToken.balanceOf(feeRecipient), 0);

        // claim yield
        uint256 aliceYield = mYieldFee.claimYieldFor(alice);
        yieldFee = mYieldFee.claimFee();
        mYieldFee.claimYieldFor(bob);

        assertEq(mYieldFee.balanceOf(alice), aliceYield);
        assertEq(mYieldFee.balanceOf(bob), 0); // Bob's yield is 0 cause he received and unwrapped in the same block

        assertEq(mYieldFee.balanceOf(feeRecipient), yieldFee);
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), aliceYield + yieldFee, 1); // May round up
        assertEq(mYieldFee.totalSupply(), aliceYield + yieldFee);
        assertEq(mYieldFee.totalAccruedYield(), 0);
        assertEq(mYieldFee.totalAccruedFee(), 0);

        // Alice and yield fee recipient unwraps
        _swapMOut(address(mYieldFee), alice, alice, aliceYield);
        _swapMOut(address(mYieldFee), feeRecipient, feeRecipient, yieldFee);

        assertEq(mYieldFee.accruedYieldOf(alice), 0);
        assertEq(mYieldFee.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), amount / 2 + aliceYield);

        assertEq(mYieldFee.accruedYieldOf(feeRecipient), 0);
        assertEq(mYieldFee.balanceOf(feeRecipient), 0);
        assertEq(mToken.balanceOf(feeRecipient), yieldFee);
        assertEq(mToken.balanceOf(address(mYieldFee)), 0);

        // wrap from earner account
        _addToList(EARNERS_LIST, bob);

        vm.prank(bob);
        mToken.startEarning();

        _swapInM(address(mYieldFee), bob, bob, amount);

        // Check balances of MYieldFee and Bob after wrapping
        assertEq(mYieldFee.balanceOf(bob), amount);
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), amount, 1);

        // Disable earning for the contract
        _removeFromList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.disableEarning();

        assertFalse(mYieldFee.isEarningEnabled());

        // Fast forward 10 days in the future
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // No yield should accrue
        assertEq(mYieldFee.totalAccruedYield(), 0);

        // Re-enable earning for the contract
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        // Yield should accrue again
        vm.warp(vm.getBlockTimestamp() + 10 days);

        assertApproxEqAbs(mYieldFee.totalAccruedYield(), totalYield - yieldFee, 3); // May round down
        assertApproxEqAbs(mToken.balanceOf(address(mYieldFee)), amount + totalYield, 1);
    }

    /* ============ updateIndex ============ */

    function test_updateIndex_earningDisabled() public {
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        // enableEarning should call updateIndex and set the latest rate
        assertNotEq(mYieldFee.latestRate(), 0);

        vm.warp(block.timestamp + 1 weeks);

        _removeFromList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.disableEarning();

        // Latest rate should be zero and earning disabled
        assertFalse(mYieldFee.isEarningEnabled());
        assertEq(mYieldFee.latestRate(), 0);

        uint256 prevIndex = mYieldFee.currentIndex();

        // Move forward by 5 blocks
        vm.warp(block.timestamp + 5 * (12 seconds));

        uint256 index = mYieldFee.currentIndex();

        // The index should not grow
        assertEq(prevIndex, index);

        mYieldFee.updateIndex();

        // Earning should not be re-activated and the index should not grow after being updated
        assertFalse(mYieldFee.isEarningEnabled());
        assertEq(mYieldFee.latestRate(), 0);
        assertEq(index, mYieldFee.currentIndex());

        vm.warp(block.timestamp + 5 * (12 seconds));
        assertEq(index, mYieldFee.currentIndex());
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

    /* ============ wrap ============ */

    function test_wrap() external {
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        assertEq(mToken.balanceOf(alice), 10e6);

        assertEq(mToken.earnerRate(), 415);
        assertEq(mYieldFee.earnerRate(), 332); // 20% fee -> 415 bps * 0.8 = 332 bps

        assertEq(mToken.currentIndex(), 1_043072100803);
        assertEq(mYieldFee.currentIndex(), 1e12);

        uint256 timeDelta = 72_426_135;

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_147378684081);
        assertEq(mYieldFee.currentIndex(), 1_079229873640);

        _giveM(alice, 1_000e6);
        _swapInM(address(mYieldFee), alice, alice, 1_000e6);

        // Total supply + yield: 1_000
        // Alice balance with yield: 1_000
        // Fee: 0
        assertEq(mYieldFee.principalOf(alice), 926_586656); // index has grown, so principal is not 1:1 with balance
        assertEq(mYieldFee.balanceOf(alice), 1_000e6);
        assertEq(mYieldFee.accruedYieldOf(alice), 0);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6);
        assertEq(mYieldFee.totalPrincipal(), 926_586656);
        assertEq(mYieldFee.totalSupply(), 1_000e6);
        assertEq(mYieldFee.totalAccruedYield(), 0);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6);
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_000e6 - 1); // Rounds down
        assertEq(mYieldFee.totalAccruedFee(), 0);

        // 10% M token index growth, 7.9% M Yield Fee index growth.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_262115863006);
        assertEq(mYieldFee.currentIndex(), 1_164737120157);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 21

        // Balance rounds up in favor of user, but -1 taken out of yield
        assertEq(mYieldFee.principalOf(alice), 926_586656);
        assertEq(mYieldFee.balanceOf(alice), 1_000e6);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 79_229873);
        assertEq(mYieldFee.totalPrincipal(), 926_586656);
        assertEq(mYieldFee.totalSupply(), 1_000e6);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6 + 79_229873 + 1); // Rounds up in favor of the protocol
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_099_999398); // Rounds down in favor of the protocol
        assertEq(mYieldFee.totalAccruedFee(), 20_769524); // 1_099_999398 - 1079_229874

        _giveM(alice, 1);
        _swapInM(address(mYieldFee), alice, alice, 1);

        assertEq(mYieldFee.principalOf(alice), 926_586656); // No change due to principal round down on wrap
        assertEq(mYieldFee.balanceOf(alice), 1_000e6 + 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873 - 1);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 79_229873);
        assertEq(mYieldFee.totalPrincipal(), 926_586656);
        assertEq(mYieldFee.totalSupply(), 1_000e6 + 1);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873 - 1);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6 + 79_229873 + 1);
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_099_999398);
        assertEq(mYieldFee.totalAccruedFee(), 20_769524);

        _giveM(alice, 2);
        _swapInM(address(mYieldFee), alice, alice, 2);

        assertEq(mYieldFee.principalOf(alice), 926_586656 + 1);
        assertEq(mYieldFee.balanceOf(alice), 1_000e6 + 1 + 2);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873 - 1 - 1);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 79_229873 + 1);
        assertEq(mYieldFee.totalPrincipal(), 926_586656 + 1);
        assertEq(mYieldFee.totalSupply(), 1_000e6 + 1 + 2);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873 - 1 - 1);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6 + 79_229873 + 1 + 1);
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_099_999398 + 2);
        assertEq(mYieldFee.totalAccruedFee(), 20_769524 + 1);

        assertEq(mToken.balanceOf(alice), 10e6);
    }

    function test_wrapWithPermits() external {
        _addToList(EARNERS_LIST, address(mYieldFee));

        assertEq(mToken.balanceOf(alice), 10e6);

        _swapInMWithPermitVRS(address(mYieldFee), alice, aliceKey, alice, 5e6, 0, block.timestamp);

        assertEq(mYieldFee.balanceOf(alice), 5e6);
        assertEq(mToken.balanceOf(alice), 5e6);

        _swapInMWithPermitVRS(address(mYieldFee), alice, aliceKey, alice, 5e6, 1, block.timestamp);

        assertEq(mYieldFee.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(alice), 0);
    }

    /* ============ unwrap ============ */

    function test_unwrap() external {
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        assertEq(mToken.balanceOf(alice), 10e6);

        assertEq(mToken.earnerRate(), 415);
        assertEq(mYieldFee.earnerRate(), 332); // 20% fee -> 415 bps * 0.8 = 332 bps

        assertEq(mToken.currentIndex(), 1_043072100803);
        assertEq(mYieldFee.currentIndex(), 1e12);

        uint256 timeDelta = 72_426_135;

        _giveM(alice, 1_000e6);
        _swapInM(address(mYieldFee), alice, alice, 1_000e6);

        // Total supply + yield: 1_000
        // Alice balance with yield: 1_000
        // Fee: 0
        assertEq(mYieldFee.principalOf(alice), 1_000e6); // index has not grown yet, so principal is 1:1 with balance
        assertEq(mYieldFee.balanceOf(alice), 1_000e6);
        assertEq(mYieldFee.accruedYieldOf(alice), 0);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6);
        assertEq(mYieldFee.totalPrincipal(), 1_000e6);
        assertEq(mYieldFee.totalSupply(), 1_000e6);
        assertEq(mYieldFee.totalAccruedYield(), 0);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6);
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_000e6 - 1); // Rounds down
        assertEq(mYieldFee.totalAccruedFee(), 0);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_147378684080);
        assertEq(mYieldFee.currentIndex(), 1_079229873640);

        // Balance rounds up in favor of user, but -1 taken out of yield
        assertEq(mYieldFee.principalOf(alice), 1_000e6);
        assertEq(mYieldFee.balanceOf(alice), 1_000e6);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 79_229873);
        assertEq(mYieldFee.totalPrincipal(), 1_000e6);
        assertEq(mYieldFee.totalSupply(), 1_000e6);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6 + 79_229873 + 1); // Rounds up in favor of the protocol
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_099_999398); // Rounds down in favor of the protocol
        assertEq(mYieldFee.totalAccruedFee(), 20_769524); // 1_099_999398 - 1079_229874

        _swapMOut(address(mYieldFee), alice, alice, 1);

        assertEq(mYieldFee.principalOf(alice), 1_000e6 - 1);
        assertEq(mYieldFee.balanceOf(alice), 1_000e6 - 1);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6 + 79_229873 - 1);
        assertEq(mYieldFee.totalPrincipal(), 999_999999);
        assertEq(mYieldFee.totalSupply(), 1_000e6 - 1);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873);
        assertEq(mYieldFee.projectedTotalSupply(), 1_079_229873);

        _swapMOut(address(mYieldFee), alice, alice, 499_999999);

        assertEq(mYieldFee.principalOf(alice), 1_000e6 - 1 - 463_293328);
        assertEq(mYieldFee.balanceOf(alice), 1_000e6 - 1 - 499_999999);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873 - 1);
        assertEq(mYieldFee.totalPrincipal(), 1_000e6 - 1 - 463_293328);
        assertEq(mYieldFee.totalSupply(), 1_000e6 - 1 - 499_999999);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873 - 1);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6 + 79_229873 - 1 - 499_999999);
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_099_999398 - 500e6);
        assertEq(mYieldFee.totalAccruedFee(), 20_769524 + 1);

        _swapMOut(address(mYieldFee), alice, alice, 500e6);

        assertEq(mYieldFee.principalOf(alice), 1_000e6 - 1 - 463_293328 - 463_293329); // 73_413342
        assertEq(mYieldFee.balanceOf(alice), 1_000e6 - 1 - 499_999999 - 500e6); // 0
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873 - 1 - 1);
        assertEq(mYieldFee.totalPrincipal(), 1_000e6 - 1 - 463_293328 - 463_293329); // 73_413342
        assertEq(mYieldFee.totalSupply(), 1_000e6 - 1 - 499_999999 - 500e6); // 0
        assertEq(mYieldFee.totalAccruedYield(), 79_229873 - 1 - 1);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6 + 79_229873 - 1 - 1 - 499_999999 - 500e6);
        assertEq(mYieldFee.totalAccruedFee(), 20_769524 + 1);

        assertEq(mToken.balanceOf(alice), 1_010e6);
        assertEq(mToken.balanceOf(address(mYieldFee)), 99_999397); // 79_229873 + 20_769524
    }

    // TODO: add unwrap with permits

    /* ============ transfer ============ */

    function test_transfer() external {
        _addToList(EARNERS_LIST, address(mYieldFee));
        mYieldFee.enableEarning();

        assertEq(mToken.balanceOf(alice), 10e6);

        assertEq(mToken.earnerRate(), 415);
        assertEq(mYieldFee.earnerRate(), 332); // 20% fee -> 415 bps * 0.8 = 332 bps

        assertEq(mToken.currentIndex(), 1_043072100803);
        assertEq(mYieldFee.currentIndex(), 1e12);

        uint256 timeDelta = 72_426_135;

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_147378684081);
        assertEq(mYieldFee.currentIndex(), 1_079229873640);

        _giveM(alice, 1_000e6);
        _swapInM(address(mYieldFee), alice, alice, 1_000e6);

        // Total supply + yield: 1_000
        // Alice balance with yield: 1_000
        // Fee: 0
        assertEq(mYieldFee.principalOf(alice), 926_586656); // index has grown, so principal is not 1:1 with balance
        assertEq(mYieldFee.balanceOf(alice), 1_000e6);
        assertEq(mYieldFee.accruedYieldOf(alice), 0);
        assertEq(mYieldFee.balanceWithYieldOf(alice), 1_000e6);
        assertEq(mYieldFee.totalPrincipal(), 926_586656);
        assertEq(mYieldFee.totalSupply(), 1_000e6);
        assertEq(mYieldFee.totalAccruedYield(), 0);
        assertEq(mYieldFee.projectedTotalSupply(), 1_000e6);
        assertEq(mToken.balanceOf(address(mYieldFee)), 1_000e6 - 1); // Rounds down
        assertEq(mYieldFee.totalAccruedFee(), 0);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_262115863006);
        assertEq(mYieldFee.currentIndex(), 1_164737120157);

        vm.prank(alice);
        mYieldFee.transfer(bob, 500e6);

        assertEq(mYieldFee.principalOf(alice), 926_586656 - 429_281416);
        assertEq(mYieldFee.balanceOf(alice), 500e6);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873);

        assertEq(mYieldFee.principalOf(bob), 429_281416);
        assertEq(mYieldFee.balanceOf(bob), 500e6);
        assertEq(mYieldFee.accruedYieldOf(bob), 0);

        assertEq(mYieldFee.totalSupply(), 1_000e6);

        // Principal is rounded up when adding and rounded down when subtracting.
        assertEq(mYieldFee.totalPrincipal(), 926_586656);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873);

        // Then index grows again and we transfer again to bob
        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_388326690878);
        assertEq(mYieldFee.currentIndex(), 1_257019095011);

        vm.prank(alice);
        mYieldFee.transfer(bob, 500e6);

        assertEq(mYieldFee.principalOf(alice), 926_586656 - 429_281416 - 397766432); // 99_538808
        assertEq(mYieldFee.balanceOf(alice), 0);
        assertEq(mYieldFee.accruedYieldOf(alice), 79_229873 + 45_892309); // 125_122182

        assertEq(mYieldFee.principalOf(bob), 429_281416 + 397_766432); // 827_047848
        assertEq(mYieldFee.balanceOf(bob), 1_000e6);
        assertEq(mYieldFee.accruedYieldOf(bob), 39_614937);

        assertEq(mYieldFee.totalSupply(), 1_000e6);

        assertEq(mYieldFee.totalPrincipal(), 926_586656);
        assertEq(mYieldFee.totalAccruedYield(), 79_229873 + 45_892309 + 39_614937); // 164_737119
    }
}
