// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { IERC20 } from ".../../lib/common/src/interfaces/IERC20.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import { WrappedMToken } from "../../lib/wrapped-m-token/src/WrappedMToken.sol";
import { EarnerManager } from "../../lib/wrapped-m-token/src/EarnerManager.sol";
import { WrappedMTokenMigratorV1 } from "../../lib/wrapped-m-token/src/WrappedMTokenMigratorV1.sol";
import { Proxy } from "../../lib/common/src/Proxy.sol";

import { IFreezable } from "../../src/components/IFreezable.sol";
import { MYieldFee } from "../../src/projects/yieldToAllWithFee/MYieldFee.sol";
import { MYieldToOne } from "../../src/projects/yieldToOne/MYieldToOne.sol";
import { SwapFacility } from "../../src/swap/SwapFacility.sol";
import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

import { MDualBackedYieldToOneHarness } from "../harness/MDualBackedYieldToOneHarness.sol";
import { MYieldToOneHarness } from "../harness/MYieldToOneHarness.sol";
import { MYieldFeeHarness } from "../harness/MYieldFeeHarness.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract SwapFacilityIntegrationTest is BaseIntegrationTest {
    // Holds USDC, USDT and wM
    address constant USER = 0x77BAB32F75996de8075eBA62aEa7b1205cf7E004;

    function setUp() public override {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_751_329);

        super.setUp();

        mYieldToOne = MYieldToOneHarness(
            Upgrades.deployTransparentProxy(
                "MYieldToOneHarness.sol:MYieldToOneHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldToOneHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager
                ),
                mExtensionDeployOptions
            )
        );

        mYieldFee = MYieldFeeHarness(
            Upgrades.deployTransparentProxy(
                "MYieldFeeHarness.sol:MYieldFeeHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldFeeHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    1_000, // 10% fee
                    feeRecipient,
                    admin,
                    feeManager,
                    claimRecipientManager
                ),
                mExtensionDeployOptions
            )
        );

        mDualBackedYieldToOne = MDualBackedYieldToOneHarness(
            Upgrades.deployTransparentProxy(
                "MDualBackedYieldToOneHarness.sol:MDualBackedYieldToOneHarness",
                admin,
                abi.encodeWithSelector(
                    MDualBackedYieldToOneHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    collateralManager,
                    USDC
                ),
                mExtensionDeployOptions
            )
        );

        _addToList(EARNERS_LIST, address(mDualBackedYieldToOne));
        _addToList(EARNERS_LIST, address(mYieldToOne));
        _addToList(EARNERS_LIST, address(mYieldFee));

        vm.prank(admin);
        swapFacility.grantRole(M_SWAPPER_ROLE, USER);

        // // TODO: Remove this when Wrapped M is upgraded to V2
        // address earnerManagerImplementation = address(new EarnerManager(registrar, admin));
        // address earnerManager = address(new Proxy(earnerManagerImplementation));
        // address wrappedMTokenImplementationV2 = address(
        //     new WrappedMToken(address(mToken), registrar, earnerManager, admin, address(swapFacility), admin)
        // );

        // // Ignore earners migration
        // address wrappedMTokenMigratorV1 = address(
        //     new WrappedMTokenMigratorV1(wrappedMTokenImplementationV2, new address[](0))
        // );

        // vm.prank(WrappedMToken(WRAPPED_M).migrationAdmin());
        // WrappedMToken(WRAPPED_M).migrate(wrappedMTokenMigratorV1);
    }

    function test_swap_mYieldToOne_to_wrappedM() public {
        uint256 amount = 1_000_000;
        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);

        mYieldToOne.approve(address(swapFacility), amount);
        swapFacility.swap(address(mYieldToOne), WRAPPED_M, amount, USER);

        uint256 wrappedMBalanceAfter = IERC20(WRAPPED_M).balanceOf(USER);

        assertApproxEqAbs(wrappedMBalanceAfter, wrappedMBalanceBefore + amount, 2); // WrappedM V1 rounding error
        assertEq(mYieldToOne.balanceOf(USER), 0);
    }

    function test_swap_mYieldToOne_to_mYieldFee() public {
        uint256 amount = 1_000_000;
        uint256 mYieldFeeBalanceBefore = IERC20(address(mYieldFee)).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);

        mYieldToOne.approve(address(swapFacility), amount);
        swapFacility.swap(address(mYieldToOne), address(mYieldFee), amount, USER);

        uint256 mYieldFeeBalanceAfter = IERC20(address(mYieldFee)).balanceOf(USER);

        assertEq(mYieldFeeBalanceAfter, mYieldFeeBalanceBefore + amount); // precise swaps
        assertEq(mYieldToOne.balanceOf(USER), 0);
    }

    function test_swap_wrappedM_to_mYieldToOne_entireBalance() public {
        uint256 amount = IERC20(WRAPPED_M).balanceOf(USER);

        assertEq(mYieldToOne.balanceOf(USER), 0);

        vm.startPrank(USER);
        IERC20(WRAPPED_M).approve(address(swapFacility), amount);
        swapFacility.swap(WRAPPED_M, address(mYieldToOne), amount, USER);

        assertApproxEqAbs(IERC20(address(mYieldToOne)).balanceOf(USER), amount, 2); // WrappedM V1 rounding error
        assertEq(IERC20(WRAPPED_M).balanceOf(USER), 0);
    }

    function test_swap_mYieldToOne_to_wrappedM_entireBalance() public {
        uint256 amount = IERC20(address(mToken)).balanceOf(USER);
        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);

        mYieldToOne.approve(address(swapFacility), amount);
        swapFacility.swap(address(mYieldToOne), WRAPPED_M, amount, USER);

        assertEq(IERC20(address(mYieldToOne)).balanceOf(USER), 0);
        assertApproxEqAbs(IERC20(WRAPPED_M).balanceOf(USER), wrappedMBalanceBefore + amount, 2); // WrappedM V1 rounding error
    }

    /// @dev Using lower fuzz runs and depth to avoid burning through RPC requests in CI
    /// forge-config: default.fuzz.runs = 100
    /// forge-config: default.fuzz.depth = 20
    /// forge-config: ci.fuzz.runs = 10
    /// forge-config: ci.fuzz.depth = 2
    function testFuzz_swap_mYieldToOne_to_wrappedM(uint256 amount) public {
        // Ensure the amount is not zero, above 1 to account for possible rounding, and does not exceed the user's balance
        vm.assume(amount > 1);
        vm.assume(amount <= IERC20(address(mToken)).balanceOf(mSource));

        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        _giveM(USER, amount);
        vm.startPrank(USER);

        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);

        mYieldToOne.approve(address(swapFacility), amount);
        swapFacility.swap(address(mYieldToOne), WRAPPED_M, amount, USER);

        uint256 wrappedMBalanceAfter = IERC20(WRAPPED_M).balanceOf(USER);

        assertApproxEqAbs(wrappedMBalanceAfter, wrappedMBalanceBefore + amount, 2); // WrappedM V1 rounding error
        assertEq(mYieldToOne.balanceOf(USER), 0);
    }

    function test_swap_wrappedM_to_mYieldToOne_frozenAccount() public {
        uint256 amount = 1_000_000;

        vm.prank(freezeManager);
        mYieldToOne.freeze(USER);

        vm.startPrank(USER);
        IERC20(WRAPPED_M).approve(address(swapFacility), amount);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, USER));
        swapFacility.swap(WRAPPED_M, address(mYieldToOne), amount, USER);
    }

    function test_swapWithPermit_vrs() public {
        uint256 amount = 1_000_000;

        // Transfer $M to Alice
        vm.prank(USER);
        IERC20(address(mToken)).transfer(alice, amount);

        // Swap $M to mYieldToOne
        vm.startPrank(alice);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, alice);

        assertEq(mYieldToOne.balanceOf(alice), amount);
        assertEq(IERC20(WRAPPED_M).balanceOf(alice), 0);

        (uint8 v, bytes32 r, bytes32 s) = _getExtensionPermit(
            address(mYieldToOne),
            address(swapFacility),
            alice,
            aliceKey,
            amount,
            0,
            block.timestamp
        );

        // Swap mYieldToOne to Wrapped M
        swapFacility.swapWithPermit(address(mYieldToOne), WRAPPED_M, amount, alice, block.timestamp, v, r, s);

        assertApproxEqAbs(IERC20(WRAPPED_M).balanceOf(alice), amount, 2);
        assertEq(mYieldToOne.balanceOf(alice), 0);
    }

    function test_swapInM() public {
        uint256 amount = 1_000_000;

        assertEq(mYieldToOne.balanceOf(USER), 0);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);
    }

    function test_swapInM_wrappedM() public {
        uint256 amount = 1_000_000;

        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(WRAPPED_M, amount, USER);

        assertApproxEqAbs(wrappedM.balanceOf(USER) - wrappedMBalanceBefore, amount, 2); // WrappedM V1 rounding error
    }

    /// @dev Using lower fuzz runs and depth to avoid burning through RPC requests in CI
    /// forge-config: default.fuzz.runs = 100
    /// forge-config: default.fuzz.depth = 20
    /// forge-config: ci.fuzz.runs = 10
    /// forge-config: ci.fuzz.depth = 2
    function testFuzz_swapInM(uint256 amount) public {
        // Ensure the amount is not zero and does not exceed the source balance
        vm.assume(amount > 0);
        vm.assume(amount <= IERC20(address(mToken)).balanceOf(mSource));

        _giveM(USER, amount);

        assertEq(mYieldToOne.balanceOf(USER), 0);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);
    }

    function test_swapInMWithPermit_vrs() public {
        uint256 amount = 1_000_000;

        vm.prank(USER);
        IERC20(address(mToken)).transfer(alice, amount);

        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(IERC20(address(mToken)).balanceOf(alice), amount);

        (uint8 v, bytes32 r, bytes32 s) = _getMPermit(
            address(swapFacility),
            alice,
            aliceKey,
            amount,
            0,
            block.timestamp
        );

        vm.prank(alice);
        swapFacility.swapInMWithPermit(address(mYieldToOne), amount, alice, block.timestamp, v, r, s);

        assertEq(mYieldToOne.balanceOf(alice), amount);
    }

    function test_swapInMWithPermit_signature() public {
        uint256 amount = 1_000_000;

        vm.prank(USER);
        IERC20(address(mToken)).transfer(alice, amount);

        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(IERC20(address(mToken)).balanceOf(alice), amount);

        (uint8 v, bytes32 r, bytes32 s) = _getMPermit(
            address(swapFacility),
            alice,
            aliceKey,
            amount,
            0,
            block.timestamp
        );

        vm.prank(alice);
        swapFacility.swapInMWithPermit(address(mYieldToOne), amount, alice, block.timestamp, abi.encodePacked(r, s, v));

        assertEq(mYieldToOne.balanceOf(alice), amount);
    }

    function test_swapInSecondary() public {
        uint256 amount = 1_000_000;

        vm.prank(USER);
        IERC20(USDC).transfer(alice, amount);

        vm.prank(alice);
        IERC20(USDC).approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.SwappedInSecondaryBacker(address(mDualBackedYieldToOne), USDC, amount, alice);

        vm.prank(alice);
        swapFacility.swapInSecondary(address(mDualBackedYieldToOne), amount, alice);

        uint256 aliceBalance = mDualBackedYieldToOne.balanceOf(alice);

        uint256 supply = mDualBackedYieldToOne.totalSupply();
        uint256 secondarySupply = mDualBackedYieldToOne.secondarySupply();

        assertEq(aliceBalance, amount, "Alice's balance should match the swapped amount");
        assertEq(secondarySupply, amount, "Secondary supply should match the swapped amount");
        assertEq(supply, amount, "Total supply should match the swapped amount");
    }

    function test_swapInSecondary_nonSecondary() public {
        vm.prank(USER);
        IERC20(address(mToken)).transfer(alice, 1_000_000);

        vm.prank(alice);
        IERC20(USDC).approve(address(swapFacility), 1_000_000);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotDualBackedExtension.selector, address(mYieldToOne)));

        vm.prank(alice);
        swapFacility.swapInSecondary(address(mYieldToOne), 1_000_000, alice);
    }

    function test_replaceSecondary() public {
        vm.prank(USER);
        mToken.transfer(alice, 1_000_000);

        vm.prank(USER);
        IERC20(USDC).transfer(address(mDualBackedYieldToOne), 1_000_000);

        vm.prank(alice);
        mToken.approve(address(swapFacility), 1_000_000);

        mDualBackedYieldToOne.setSecondarySupply(1_000_000);
        mDualBackedYieldToOne.setTotalSupply(1_000_000);
        mDualBackedYieldToOne.setBalanceOf(alice, 1_000_000);

        vm.expectEmit();
        emit ISwapFacility.ReplacedSecondaryBacker(address(mDualBackedYieldToOne), USDC, 1_000_000);

        vm.prank(alice);
        swapFacility.replaceSecondary(address(mDualBackedYieldToOne), 1_000_000, alice);

        assertEq(IERC20(USDC).balanceOf(alice), 1_000_000);
        assertEq(mToken.balanceOf(address(mDualBackedYieldToOne)), 1_000_000);
        assertEq(mDualBackedYieldToOne.secondarySupply(), 0);
    }

    function test_swapOutM() public {
        uint256 amount = 1_000_000;

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);

        uint256 mBalanceBefore = IERC20(address(mToken)).balanceOf(USER);

        mYieldToOne.approve(address(swapFacility), amount);
        swapFacility.swapOutM(address(mYieldToOne), amount, USER);

        uint256 mBalanceAfter = IERC20(address(mToken)).balanceOf(USER);

        assertEq(mYieldToOne.balanceOf(USER), 0);
        assertEq(mBalanceAfter - mBalanceBefore, amount);
    }

    function test_swapOutM_wrappedM() public {
        uint256 amount = 1_000_000;

        assertTrue(wrappedM.balanceOf(USER) >= amount, "Insufficient Wrapped M balance");

        uint256 mBalanceBefore = IERC20(address(mToken)).balanceOf(USER);

        vm.startPrank(USER);

        wrappedM.approve(address(swapFacility), amount);
        swapFacility.swapOutM(address(wrappedM), amount, USER);

        uint256 mBalanceAfter = IERC20(address(mToken)).balanceOf(USER);

        assertApproxEqAbs(mBalanceAfter - mBalanceBefore, amount, 2); // WrappedM V1 rounding error
    }

    /// @dev Using lower fuzz runs and depth to avoid burning through RPC requests in CI
    /// forge-config: default.fuzz.runs = 100
    /// forge-config: default.fuzz.depth = 20
    /// forge-config: ci.fuzz.runs = 10
    /// forge-config: ci.fuzz.depth = 2
    function testFuzz_swapOutM(uint256 amount) public {
        // Ensure the amount is not zero and does not exceed the source balance
        vm.assume(amount > 0);
        vm.assume(amount <= IERC20(address(mToken)).balanceOf(mSource));

        _giveM(USER, amount);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, USER);

        assertEq(mYieldToOne.balanceOf(USER), amount);

        uint256 mBalanceBefore = IERC20(address(mToken)).balanceOf(USER);

        mYieldToOne.approve(address(swapFacility), amount);
        swapFacility.swapOutM(address(mYieldToOne), amount, USER);

        uint256 mBalanceAfter = IERC20(address(mToken)).balanceOf(USER);

        assertEq(mYieldToOne.balanceOf(USER), 0);
        assertEq(mBalanceAfter - mBalanceBefore, amount);
    }

    function test_swapOutMWithPermit_vrs() public {
        uint256 amount = 1_000_000;

        // Transfer $M to Alice
        vm.prank(USER);
        IERC20(address(mToken)).transfer(alice, amount);

        // Swap $M to mYieldToOne
        vm.startPrank(alice);
        IERC20(address(mToken)).approve(address(swapFacility), amount);
        swapFacility.swapInM(address(mYieldToOne), amount, alice);

        assertEq(mYieldToOne.balanceOf(alice), amount);
        assertEq(IERC20(address(mToken)).balanceOf(alice), 0);

        (uint8 v, bytes32 r, bytes32 s) = _getExtensionPermit(
            address(mYieldToOne),
            address(swapFacility),
            alice,
            aliceKey,
            amount,
            0,
            block.timestamp
        );

        // Swap mYieldToOne to M
        swapFacility.swapOutMWithPermit(address(mYieldToOne), amount, alice, block.timestamp, v, r, s);

        assertEq(IERC20(address(mToken)).balanceOf(alice), amount);
        assertEq(mYieldToOne.balanceOf(alice), 0);
    }
}
