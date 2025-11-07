// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MEarnerManager } from "../../src/projects/earnerManager/MEarnerManager.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract MEarnerManagerIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    function setUp() public override {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_482_175);

        super.setUp();

        _fundAccounts();

        mEarnerManager = MEarnerManager(
            Upgrades.deployTransparentProxy(
                "MEarnerManager.sol:MEarnerManager",
                admin,
                abi.encodeWithSelector(
                    MEarnerManager.initialize.selector,
                    NAME,
                    SYMBOL,
                    admin,
                    earnerManager,
                    feeRecipient
                ),
                mExtensionDeployOptions
            )
        );
    }

    function test_integration_constants() external view {
        assertEq(mEarnerManager.name(), NAME);
        assertEq(mEarnerManager.symbol(), SYMBOL);
        assertEq(mEarnerManager.decimals(), 6);
        assertEq(mEarnerManager.mToken(), address(mToken));
        assertEq(mEarnerManager.feeRecipient(), feeRecipient);
        assertEq(mEarnerManager.ONE_HUNDRED_PERCENT(), 10_000);
        assertTrue(mEarnerManager.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mEarnerManager.hasRole(EARNER_MANAGER_ROLE, earnerManager));
    }

    /* ============ yield ============ */

    function test_yieldAccumulationAndClaim() external {
        // Enable earning for the contract
        _addToList(EARNERS_LIST, address(mEarnerManager));
        mEarnerManager.enableEarning();

        // Check the initial earning state
        assertEq(mToken.isEarning(address(mEarnerManager)), true);
        assertEq(mEarnerManager.isEarningEnabled(), true);

        // Add earners with different fee rates
        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 10_000); // 100% fee

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(bob, true, 5_000); // 50% fee

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(carol, true, 0); // 0% fee

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(david, true, 0);

        uint256 amount = 10e6;

        // Wraps
        vm.prank(admin);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        vm.prank(alice);
        mToken.approve(address(swapFacility), amount);

        vm.prank(alice);
        swapFacility.swap(address(mToken), address(mEarnerManager), amount, alice);

        vm.prank(admin);
        swapFacility.grantRole(M_SWAPPER_ROLE, bob);

        vm.prank(bob);
        mToken.approve(address(swapFacility), amount);

        vm.prank(bob);
        swapFacility.swap(address(mToken), address(mEarnerManager), amount, bob);

        vm.prank(admin);
        swapFacility.grantRole(M_SWAPPER_ROLE, carol);

        vm.prank(carol);
        mToken.approve(address(swapFacility), amount);

        vm.prank(carol);
        swapFacility.swap(address(mToken), address(mEarnerManager), amount, carol);

        // Check balances of MEarnerManager and users after wrapping
        assertEq(mEarnerManager.balanceOf(alice), amount);
        assertEq(mEarnerManager.balanceOf(bob), amount);
        assertEq(mEarnerManager.balanceOf(carol), amount);
        assertEq(mEarnerManager.totalSupply(), amount * 3); // 3 users wrapped

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(bob), 0);
        assertEq(mToken.balanceOf(carol), 0);

        assertApproxEqAbs(mToken.balanceOf(address(mEarnerManager)), amount * 3, 6); // 3 users wrapped
        assertEq(mEarnerManager.currentIndex(), mToken.currentIndex());

        vm.warp(vm.getBlockTimestamp() + 1 days);

        (uint256 aliceYieldWithFee, uint256 aliceFee, uint256 aliceYield) = mEarnerManager.accruedYieldAndFeeOf(alice);
        (uint256 bobYieldWithFee, uint256 bobFee, uint256 bobYield) = mEarnerManager.accruedYieldAndFeeOf(bob);
        (uint256 carolYieldWithFee, uint256 carolFee, uint256 carolYield) = mEarnerManager.accruedYieldAndFeeOf(carol);

        // Total accrued yield for all users should be the same
        assertEq(aliceYieldWithFee, bobYieldWithFee);
        assertEq(aliceYieldWithFee, carolYieldWithFee);

        assertEq(aliceFee, aliceYieldWithFee); // 100% fee for Alice
        assertEq(bobFee, bobYieldWithFee / 2); // 50% fee for Bob
        assertEq(carolFee, 0); // 0% fee for Carol

        assertEq(aliceYieldWithFee, aliceFee + aliceYield);
        assertEq(bobYieldWithFee, bobFee + bobYield);
        assertEq(carolYieldWithFee, carolFee + carolYield);

        vm.prank(alice);
        mEarnerManager.transfer(david, amount / 2);

        (uint256 aliceYieldWithFee1, , ) = mEarnerManager.accruedYieldAndFeeOf(alice);

        assertApproxEqAbs(aliceYieldWithFee1, aliceYieldWithFee, 2); // Unclaimed yield does not change after transfer

        (aliceYieldWithFee, aliceFee, ) = mEarnerManager.claimFor(alice);
        (bobYieldWithFee, bobFee, ) = mEarnerManager.claimFor(bob);
        (carolYieldWithFee, carolFee, ) = mEarnerManager.claimFor(carol);

        assertEq(mEarnerManager.balanceOf(feeRecipient), aliceFee + bobFee + carolFee);

        // After claiming accrued yield is 0
        assertEq(mEarnerManager.accruedYieldOf(alice), 0);
        assertEq(mEarnerManager.accruedYieldOf(bob), 0);
        assertEq(mEarnerManager.accruedYieldOf(carol), 0);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        uint256 feeRecipientYield = mEarnerManager.accruedYieldOf(feeRecipient);

        mEarnerManager.claimFor(feeRecipient);

        assertEq(mEarnerManager.balanceOf(feeRecipient), aliceFee + bobFee + carolFee + feeRecipientYield);
    }

    function test_yieldRecipient() external {
        // Enable earning for the contract
        _addToList(EARNERS_LIST, address(mEarnerManager));
        mEarnerManager.enableEarning();

        // Add earners with different fee rates
        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 1_000); // 10% fee

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(bob, true, 1_000); // 10% fee

        uint256 amount = 10e6;

        // Mint tokens for Alice
        vm.prank(alice);
        mToken.approve(address(swapFacility), amount);
        vm.prank(alice);
        swapFacility.swap(address(mToken), address(mEarnerManager), amount, alice);

        // Mint tokens for Bob
        vm.prank(bob);
        mToken.approve(address(swapFacility), amount);
        vm.prank(bob);
        swapFacility.swap(address(mToken), address(mEarnerManager), amount, bob);

        vm.warp(vm.getBlockTimestamp() + 365 days);

        assertEq(mEarnerManager.balanceOf(feeRecipient), 0);

        (uint256 bobYield, uint256 bobFee, uint256 bobYieldNetOfFees) = mEarnerManager.accruedYieldAndFeeOf(bob);

        vm.prank(earnerManager);
        mEarnerManager.setFeeRecipient(bob);

        assertEq(mEarnerManager.balanceOf(feeRecipient), bobFee);
        assertEq(mEarnerManager.balanceOf(bob), amount + bobYieldNetOfFees);

        (uint256 aliceYield, uint256 aliceFee, uint256 aliceYieldNetOfFees) = mEarnerManager.claimFor(alice);

        assertEq(aliceFee, (10 * aliceYield) / 100); // 10% fee for Alice

        assertEq(mEarnerManager.balanceOf(bob), amount + bobYieldNetOfFees + aliceFee);
        assertEq(mEarnerManager.balanceOf(feeRecipient), bobFee);
        assertEq(mEarnerManager.balanceOf(alice), amount + aliceYieldNetOfFees);

        (bobYield, bobFee, bobYieldNetOfFees) = mEarnerManager.claimFor(bob);

        // Bob unclaimed yield is 0 after `mEarnerManager.setFeeRecipient(bob)` call
        assertEq(bobYield, 0);
        assertEq(bobFee, 0);
        assertEq(bobYieldNetOfFees, 0);
    }

    /* ============ wrap ============ */

    function test_wrap() external {
        _addToList(EARNERS_LIST, address(mEarnerManager));
        mEarnerManager.enableEarning();

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 1_000); // 10% fee

        assertEq(mToken.balanceOf(alice), 10e6);

        assertEq(mToken.currentIndex(), 1_043072100803);
        assertEq(mEarnerManager.currentIndex(), 1_043072100803);

        uint256 timeDelta = 72_426_135;

        // 10% M token index growth == 10% M Earner Manager index growth
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_147378684081);
        assertEq(mEarnerManager.currentIndex(), 1_147378684081);

        _giveM(alice, 1_000e6);
        _swapInM(address(mEarnerManager), alice, alice, 1_000e6);

        // Total supply + yield: 1_000
        // Alice balance with yield: 1_000
        // Fee: 0
        assertEq(mEarnerManager.principalOf(alice), 871_551837); // index has grown, so principal is not 1:1 with balance
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6);
        assertEq(mEarnerManager.accruedYieldOf(alice), 0);
        assertEq(mEarnerManager.accruedFeeOf(alice), 0);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6);
        assertEq(mEarnerManager.totalPrincipal(), 871_551837);
        assertEq(mEarnerManager.totalSupply(), 1_000e6);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_000e6 - 1); // Rounds down

        // 10% M token index growth == 10% M Earner Manager index growth.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_262115863006);
        assertEq(mEarnerManager.currentIndex(), 1_262115863006);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 21

        // Balance rounds up in favor of user, but -1 taken out of yield
        assertEq(mEarnerManager.principalOf(alice), 871_551837);
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6 + 89_999459);
        assertEq(mEarnerManager.totalPrincipal(), 871_551837);
        assertEq(mEarnerManager.totalSupply(), 1_000e6);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939 + 1); // Rounds up in favor of the protocol
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_099_999398); // Rounds down in favor of the protocol

        _giveM(alice, 1);
        _swapInM(address(mEarnerManager), alice, alice, 1);

        assertEq(mEarnerManager.principalOf(alice), 871_551837); // No change due to principal round down on wrap
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6 + 1);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459 - 1);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6 + 89_999459);
        assertEq(mEarnerManager.totalPrincipal(), 871_551837);
        assertEq(mEarnerManager.totalSupply(), 1_000e6 + 1);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939 + 1);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_099_999398);

        _giveM(alice, 2);
        _swapInM(address(mEarnerManager), alice, alice, 2);

        assertEq(mEarnerManager.principalOf(alice), 871_551837 + 1);
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6 + 1 + 2);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459 - 1);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6 + 89_999459 + 1 + 1);
        assertEq(mEarnerManager.totalPrincipal(), 871_551837 + 1);
        assertEq(mEarnerManager.totalSupply(), 1_000e6 + 1 + 2);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939 + 1 + 2);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_099_999398 + 2);

        assertEq(mToken.balanceOf(alice), 10e6);
    }

    function test_wrapWithPermits() external {
        _addToList(EARNERS_LIST, address(mEarnerManager));
        mEarnerManager.enableEarning();

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 1_000); // 10% fee

        assertEq(mToken.balanceOf(alice), 10e6);

        _swapInMWithPermitVRS(address(mEarnerManager), alice, aliceKey, alice, 5e6, 0, block.timestamp);

        assertEq(mEarnerManager.balanceOf(alice), 5e6);
        assertEq(mToken.balanceOf(alice), 5e6);

        _swapInMWithPermitSignature(address(mEarnerManager), alice, aliceKey, alice, 5e6, 1, block.timestamp);

        assertEq(mEarnerManager.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(alice), 0);
    }

    /* ============ unwrap ============ */

    function test_unwrap() external {
        _addToList(EARNERS_LIST, address(mEarnerManager));
        mEarnerManager.enableEarning();

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 1_000); // 10% fee

        // TODO: is this needed? Revert otherwise when approving swap facility to spend M Earner Manager
        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(address(swapFacility), true, 0);

        assertEq(mToken.balanceOf(alice), 10e6);

        assertEq(mToken.currentIndex(), 1_043072100803);
        assertEq(mEarnerManager.currentIndex(), 1_043072100803);

        uint256 timeDelta = 72_426_135;

        _giveM(alice, 1_000e6);
        _swapInM(address(mEarnerManager), alice, alice, 1_000e6);

        // Total supply + yield: 1_000
        // Alice balance with yield: 1_000
        // Fee: 0
        assertEq(mEarnerManager.principalOf(alice), 958_706497); // index has grown, so principal is not 1:1 with balance
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6);
        assertEq(mEarnerManager.accruedYieldOf(alice), 0);
        assertEq(mEarnerManager.accruedFeeOf(alice), 0);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6);
        assertEq(mEarnerManager.totalPrincipal(), 958_706497);
        assertEq(mEarnerManager.totalSupply(), 1_000e6);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_000e6 - 1); // Rounds down

        // 10% M token index growth == 10% M Earner Manager index growth.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_147378684080);
        assertEq(mEarnerManager.currentIndex(), 1_147378684080);

        // Balance rounds up in favor of user, but -1 taken out of yield
        assertEq(mEarnerManager.principalOf(alice), 958_706497);
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6 + 89_999459);
        assertEq(mEarnerManager.totalPrincipal(), 958_706497);
        assertEq(mEarnerManager.totalSupply(), 1_000e6);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939 + 1); // Rounds up in favor of the protocol
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_099_999398); // Rounds down in favor of the protocol

        _swapMOut(address(mEarnerManager), alice, alice, 1);

        assertEq(mEarnerManager.principalOf(alice), 958_706497 - 1);
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6 - 1);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6 + 89_999459 - 1);
        assertEq(mEarnerManager.totalPrincipal(), 958_706497 - 1);
        assertEq(mEarnerManager.totalSupply(), 1_000e6 - 1);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_099_999398 - 1);

        _swapMOut(address(mEarnerManager), alice, alice, 499_999999);

        assertEq(mEarnerManager.principalOf(alice), 958_706497 - 1 - 435_775918);
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6 - 1 - 499_999999);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6 + 89_999459 - 1 - 499_999999);
        assertEq(mEarnerManager.totalPrincipal(), 958_706497 - 1 - 435_775918);
        assertEq(mEarnerManager.totalSupply(), 1_000e6 - 1 - 499_999999);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939 - 499_999999);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_099_999398 - 1 - 499_999999);

        _swapMOut(address(mEarnerManager), alice, alice, 500e6);

        assertEq(mEarnerManager.principalOf(alice), 958_706497 - 1 - 435_775919 - 435_775918); // 87_154659
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6 - 1 - 499_999999 - 500e6); // 0
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459 - 1);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6 + 89_999459 - 1 - 499_999999 - 500e6 - 1);
        assertEq(mEarnerManager.totalPrincipal(), 958_706497 - 1 - 435_775919 - 435_775918); // 87_154659
        assertEq(mEarnerManager.totalSupply(), 1_000e6 - 1 - 499_999999 - 500e6); // 0
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939 - 499_999999 - 500e6 - 1);

        assertEq(mToken.balanceOf(alice), 1_010e6);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 89_999459 + 9_999939 - 1);
    }

    // TODO: add unwrap with permits test
    // function test_unwrapWithPermits() external {
    //     _addToList(EARNERS_LIST, address(mEarnerManager));
    //     mEarnerManager.enableEarning();
    //
    //     vm.prank(earnerManager);
    //     mEarnerManager.setAccountInfo(alice, true, 0); // 0% fee for simplicity
    //
    //     _giveM(alice, 1_000e6);
    //     _swapInM(address(mEarnerManager), alice, alice, 1_000e6);
    //
    //     assertEq(mEarnerManager.balanceOf(alice), 1_000e6);
    //     assertEq(mToken.balanceOf(address(mEarnerManager)), 1_000e6 - 1);
    //
    //     _swapMOutWithPermitVRS(address(mEarnerManager), alice, aliceKey, alice, 500e6, 0, block.timestamp);
    //
    //     assertEq(mEarnerManager.balanceOf(alice), 500e6);
    //     assertEq(mToken.balanceOf(alice), 10e6 + 500e6);
    //
    //     _swapMOutWithPermitSignature(address(mEarnerManager), alice, aliceKey, alice, 500e6, 1, block.timestamp);
    //
    //     assertEq(mEarnerManager.balanceOf(alice), 0);
    //     assertEq(mToken.balanceOf(alice), 10e6 + 1_000e6);
    // }

    /* ============ transfer ============ */

    function test_transfer() external {
        _addToList(EARNERS_LIST, address(mEarnerManager));
        mEarnerManager.enableEarning();

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 1_000); // 10% fee

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(bob, true, 1_000); // 10% fee

        assertEq(mToken.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(bob), 10e6);

        assertEq(mToken.currentIndex(), 1_043072100803);
        assertEq(mEarnerManager.currentIndex(), 1_043072100803);

        uint256 timeDelta = 72_426_135;

        // 10% M token index growth == 10% M Earner Manager index growth
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_147378684081);
        assertEq(mEarnerManager.currentIndex(), 1_147378684081);

        _giveM(alice, 1_000e6);
        _swapInM(address(mEarnerManager), alice, alice, 1_000e6);

        // Total supply + yield: 1_000
        // Alice balance with yield: 1_000
        // Fee: 0
        assertEq(mEarnerManager.principalOf(alice), 871_551837); // index has grown, so principal is not 1:1 with balance
        assertEq(mEarnerManager.balanceOf(alice), 1_000e6);
        assertEq(mEarnerManager.accruedYieldOf(alice), 0);
        assertEq(mEarnerManager.accruedFeeOf(alice), 0);
        assertEq(mEarnerManager.balanceWithYieldOf(alice), 1_000e6);
        assertEq(mEarnerManager.totalPrincipal(), 871_551837);
        assertEq(mEarnerManager.totalSupply(), 1_000e6);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6);
        assertEq(mToken.balanceOf(address(mEarnerManager)), 1_000e6 - 1); // Rounds down

        // 10% M token index growth == 10% M Earner Manager index growth.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_262115863006);
        assertEq(mEarnerManager.currentIndex(), 1_262115863006);

        vm.prank(alice);
        mEarnerManager.transfer(bob, 500e6);

        assertEq(mEarnerManager.principalOf(alice), 871_551837 - 396_160143);
        assertEq(mEarnerManager.balanceOf(alice), 500e6);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939);

        assertEq(mEarnerManager.principalOf(bob), 396_160143);
        assertEq(mEarnerManager.balanceOf(bob), 500e6);
        assertEq(mEarnerManager.accruedYieldOf(bob), 0);
        assertEq(mEarnerManager.accruedFeeOf(bob), 0);

        assertEq(mEarnerManager.totalSupply(), 1_000e6);

        // Principal is rounded up when adding and rounded down when subtracting.
        assertEq(mEarnerManager.totalPrincipal(), 871_551837);
        assertEq(mEarnerManager.projectedTotalSupply(), 1_000e6 + 89_999459 + 9_999939 + 1);

        // Then index grows again and we transfer again to bob
        // 10% M token index growth == 10% M Earner Manager index growth.
        vm.warp(vm.getBlockTimestamp() + timeDelta);

        assertEq(mToken.currentIndex(), 1_388326690878);
        assertEq(mEarnerManager.currentIndex(), 1_388326690878);

        vm.prank(alice);
        mEarnerManager.transfer(bob, 500e6);

        assertEq(mEarnerManager.principalOf(alice), 871_551837 - 396_160143 - 360_145781); // 115_245913
        assertEq(mEarnerManager.balanceOf(alice), 0);
        assertEq(mEarnerManager.accruedYieldOf(alice), 89_999459 + 53_999621);
        assertEq(mEarnerManager.accruedFeeOf(alice), 9_999939 + 5_999958);

        assertEq(mEarnerManager.principalOf(bob), 396_160143 + 360_145781); // 1_231_697617
        assertEq(mEarnerManager.balanceOf(bob), 1_000e6);
        assertEq(mEarnerManager.accruedYieldOf(bob), 44_999730);
        assertEq(mEarnerManager.accruedFeeOf(bob), 4_999970);

        assertEq(mEarnerManager.totalSupply(), 1_000e6);

        assertEq(mEarnerManager.totalPrincipal(), 871_551837);
        assertEq(
            mEarnerManager.projectedTotalSupply(),
            1_000e6 + 89_999459 + 53_999621 + 9_999939 + 5_999958 + 44_999730 + 4_999970 + 1
        );
    }
}
