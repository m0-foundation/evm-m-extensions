// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../../lib/common/src/interfaces/IERC20Extended.sol";

import {
    IAccessControl
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MockERC20, MockM } from "../../utils/Mocks.sol";

import { MDualBackedYieldToOne } from "../../../src/projects/dualBackedYieldToOne/MDualBackedYieldToOne.sol";
import { IMDualBackedYieldToOne } from "../../../src/projects/dualBackedYieldToOne/IMDualBackedYieldToOne.sol";
import { IMYieldToOne } from "../../../src/projects/yieldToOne/IMYieldToOne.sol";

import { IFreezable } from "../../../src/components/IFreezable.sol";
import { IMExtension } from "../../../src/interfaces/IMExtension.sol";

import { ISwapFacility } from "../../../src/swap/interfaces/ISwapFacility.sol";

import { MDualBackedYieldToOneHarness } from "../../harness/MDualBackedYieldToOneHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract MYDualBackedYieldToOneUnitTests is BaseUnitTest {
    MDualBackedYieldToOneHarness public mDualBackedToOne;
    MDualBackedYieldToOneHarness public mDualBackedToOneDiffDecimals;

    string public constant NAME = "M Dual Backed Yield to One";
    string public constant SYMBOL = "MDBYO";

    MockERC20 public secondary;
    MockERC20 public secondary18Decimals;

    function setUp() public override {
        super.setUp();

        secondary = new MockERC20("MockSecondaryToken", "MST", 6);
        secondary18Decimals = new MockERC20("MockSecondaryToken18", "MST18", 18);

        mDualBackedToOne = MDualBackedYieldToOneHarness(
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
                    address(secondary)
                ),
                mExtensionDeployOptions
            )
        );

        mDualBackedToOneDiffDecimals = MDualBackedYieldToOneHarness(
            Upgrades.deployTransparentProxy(
                "MDualBackedYieldToOneHarness.sol:MDualBackedYieldToOneHarness",
                admin,
                abi.encodeWithSelector(
                    MDualBackedYieldToOneHarness.initialize.selector,
                    "HALO18",
                    "HALO18",
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    address(secondary18Decimals)
                ),
                mExtensionDeployOptions
            )
        );

        registrar.setEarner(address(mDualBackedToOne), true);
        registrar.setEarner(address(mDualBackedToOneDiffDecimals), true);

        vm.prank(address(swapFacility));
        secondary.approve(address(mDualBackedToOne), type(uint256).max);

        vm.prank(address(swapFacility));
        secondary18Decimals.approve(address(mDualBackedToOneDiffDecimals), type(uint256).max);
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertEq(mDualBackedToOne.name(), NAME);
        assertEq(mDualBackedToOne.symbol(), SYMBOL);
        assertEq(mDualBackedToOne.decimals(), 6);
        assertEq(mDualBackedToOne.mToken(), address(mToken));
        assertEq(mDualBackedToOne.swapFacility(), address(swapFacility));
        assertEq(mDualBackedToOne.yieldRecipient(), yieldRecipient);

        assertEq(mDualBackedToOne.secondaryToken(), address(secondary));
        assertEq(mDualBackedToOne.secondaryDecimals(), 6);
        assertEq(mDualBackedToOne.M_DECIMALS(), 6);

        assertTrue(IAccessControl(address(mDualBackedToOne)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(
            IAccessControl(address(mDualBackedToOne)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager)
        );
    }

    function test_initialize_secondaryToken18Decimals() external {
        assertEq(mDualBackedToOneDiffDecimals.secondaryDecimals(), 18);
        assertEq(mDualBackedToOneDiffDecimals.secondaryToken(), address(secondary18Decimals));
    }

    function test_initialize_zeroSecondaryToken() external {
        address implementation = address(new MDualBackedYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedYieldToOne.ZeroSecondaryToken.selector);
        MDualBackedYieldToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedYieldToOneHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    address(0)
                )
            )
        );
    }

    /* ============ swapSecondary ============ */

    function test_swapSecondary_onlySwapFacility() external {
        vm.expectRevert(IMExtension.NotSwapFacility.selector);

        vm.prank(alice);
        mDualBackedToOne.wrap(alice, 0);
    }

    function test_swapSecondary_invalidRecipient() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrap(address(0), 1);
    }

    function test_swapSecondary_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrap(alice, 0);
    }

    function test_swapSecondary() public {
        uint256 amount = 1_000e6;

        mToken.setBalanceOf(address(swapFacility), amount);
        assertEq(mToken.balanceOf(address(swapFacility)), amount);

        secondary.mint(address(mDualBackedToOne), amount);
        assertEq(secondary.balanceOf(address(mDualBackedToOne)), amount);

        vm.expectEmit();
        emit IERC20.Transfer(address(mDualBackedToOne), alice, amount);

        vm.expectEmit();
        emit IMDualBackedYieldToOne.SwappedSecondaryToken(address(secondary), amount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.swapSecondary(alice, amount);

        assertEq(mDualBackedToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 0);

        assertEq(secondary.balanceOf(address(mDualBackedToOne)), 0);
        assertEq(secondary.balanceOf(alice), amount);
    }

    function test_swapSecondary_diffDecimals() public {
        uint256 secondaryAmount = 1e18;
        uint256 extensionAmount = 1e6;

        mToken.setBalanceOf(address(swapFacility), extensionAmount);
        assertEq(mToken.balanceOf(address(swapFacility)), extensionAmount);

        secondary18Decimals.mint(address(mDualBackedToOneDiffDecimals), secondaryAmount);
        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOneDiffDecimals)), secondaryAmount);

        vm.expectEmit();
        emit IERC20.Transfer(address(mDualBackedToOneDiffDecimals), alice, secondaryAmount);

        vm.expectEmit();
        emit IMDualBackedYieldToOne.SwappedSecondaryToken(address(secondary18Decimals), secondaryAmount);

        vm.prank(address(swapFacility));
        mDualBackedToOneDiffDecimals.swapSecondary(alice, secondaryAmount);

        assertEq(mDualBackedToOneDiffDecimals.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 0);

        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOneDiffDecimals)), 0);
        assertEq(secondary18Decimals.balanceOf(alice), secondaryAmount);
    }

    /* ============ wrapSecondary ============ */

    function test_wrapSecondary_onlySwapFacility() external {
        vm.expectRevert(IMExtension.NotSwapFacility.selector);

        vm.prank(alice);
        mDualBackedToOne.wrap(alice, 0);
    }

    function test_wrapSecondary_invalidRecipient() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrap(address(0), 1);
    }

    function test_wrapSecondary_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrap(alice, 0);
    }

    function test_wrapSecondary() public {
        uint256 amount = 1_000e6;

        secondary.mint(address(swapFacility), amount);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, amount);

        vm.expectEmit();
        emit IMDualBackedYieldToOne.WrappedSecondaryToken(address(secondary), amount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrapSecondary(alice, amount);

        assertEq(mDualBackedToOne.balanceOf(alice), amount);
        assertEq(mDualBackedToOne.totalSupply(), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(secondary.balanceOf(address(mDualBackedToOne)), amount);
    }

    function test_wrapSecondary_diffDecimals() public {
        uint256 secondaryAmount = 1e18;
        uint256 extensionAmount = 1e6;

        secondary18Decimals.mint(address(swapFacility), secondaryAmount);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, extensionAmount);

        vm.expectEmit();
        emit IMDualBackedYieldToOne.WrappedSecondaryToken(address(secondary18Decimals), secondaryAmount);

        vm.prank(address(swapFacility));
        mDualBackedToOneDiffDecimals.wrapSecondary(alice, secondaryAmount);

        assertEq(mDualBackedToOneDiffDecimals.balanceOf(alice), extensionAmount);
        assertEq(mDualBackedToOneDiffDecimals.totalSupply(), extensionAmount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOneDiffDecimals)), secondaryAmount);
    }

    /* ============ unwrap ============ */

    function test_unwrap_insufficientMBacking() public {
        uint256 amount = 1_000e6;
        uint256 unwrapAmount = 1e6;

        mDualBackedToOne.setBalanceOf(address(swapFacility), amount);

        secondary.mint(address(mDualBackedToOne), amount);

        vm.expectRevert(abi.encodeWithSelector(IMDualBackedYieldToOne.InsufficientMBacking.selector, unwrapAmount, 0));

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, unwrapAmount);
    }

    function test_unwrap() public {
        uint256 amount = 1_000e6;
        uint256 unwrapAmount = 1e6;
        uint256 mDualSupply = amount * 2;
        uint256 totalUnwrapAmount = 0;

        mDualBackedToOne.setBalanceOf(address(swapFacility), mDualSupply);
        mDualBackedToOne.setTotalSupply(mDualSupply);

        mToken.setBalanceOf(address(mDualBackedToOne), amount);
        secondary.mint(address(mDualBackedToOne), amount);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), unwrapAmount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, unwrapAmount);

        mDualSupply -= unwrapAmount;
        totalUnwrapAmount += unwrapAmount;

        assertEq(mDualBackedToOne.totalSupply(), mDualSupply);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), mDualSupply);
        assertEq(mToken.balanceOf(address(swapFacility)), totalUnwrapAmount);

        unwrapAmount = 499e6;

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), unwrapAmount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, unwrapAmount);

        mDualSupply -= unwrapAmount;
        totalUnwrapAmount += unwrapAmount;

        assertEq(mDualBackedToOne.totalSupply(), mDualSupply);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), mDualSupply);
        assertEq(mToken.balanceOf(address(swapFacility)), totalUnwrapAmount);

        unwrapAmount = 500e6;

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), unwrapAmount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, unwrapAmount);

        mDualSupply -= unwrapAmount;
        totalUnwrapAmount += unwrapAmount;

        assertEq(mDualBackedToOne.totalSupply(), mDualSupply);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), mDualSupply);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), totalUnwrapAmount);
        assertEq(mToken.balanceOf(address(mDualBackedToOne)), 0);
    }

    /* ============ yield ============ */

    function testFuzz_yield_withSecondary(uint256 mBalance, uint256 secondarySupply, uint256 totalSupply) external {
        mBalance = bound(mBalance, 0, type(uint128).max);
        secondarySupply = bound(secondarySupply, 0, type(uint128).max);
        totalSupply = bound(totalSupply, 0, mBalance + secondarySupply);

        if (totalSupply < secondarySupply) secondarySupply = totalSupply;

        mToken.setBalanceOf(address(mDualBackedToOne), mBalance);
        // mDualBackedToOne.setSecondarySupply(secondarySupply);
        mDualBackedToOne.setTotalSupply(totalSupply);

        assertEq(mDualBackedToOne.yield(), mBalance - (totalSupply - secondarySupply));
    }

    /* ============ claimYield ============ */

    function test_claimYield() external {
        uint256 yield = 500e6;

        secondary.mint(address(mDualBackedToOne), 1_500e6);
        mToken.setBalanceOf(address(mDualBackedToOne), 1_500e6);
        mDualBackedToOne.setTotalSupply(2_500e6);

        assertEq(mDualBackedToOne.yield(), yield);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(yield);

        assertEq(mDualBackedToOne.claimYield(), yield);
        assertEq(mDualBackedToOne.yield(), 0);

        assertEq(mToken.balanceOf(address(mDualBackedToOne)), 1_500e6);
        assertEq(mDualBackedToOne.totalSupply(), 3_000e6);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mDualBackedToOne.balanceOf(yieldRecipient), yield);
    }

    function test_claimYield_diffDecimals() external {
        // Expected yield = (secondarySupply + mBalance) - totalSupply = 500e6
        uint256 secondarySupply = 1_500e18;
        uint256 mBalance = 1_500e6;
        uint256 totalSupply = 2_500e6;
        uint256 expectedYield = 500e6;

        secondary18Decimals.mint(address(mDualBackedToOneDiffDecimals), secondarySupply);
        mToken.setBalanceOf(address(mDualBackedToOneDiffDecimals), mBalance);
        mDualBackedToOneDiffDecimals.setTotalSupply(totalSupply);

        assertEq(mDualBackedToOneDiffDecimals.yield(), expectedYield);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(expectedYield);

        assertEq(mDualBackedToOneDiffDecimals.claimYield(), expectedYield);
        assertEq(mDualBackedToOneDiffDecimals.yield(), 0);

        assertEq(mToken.balanceOf(address(mDualBackedToOneDiffDecimals)), mBalance);
        assertEq(mDualBackedToOneDiffDecimals.totalSupply(), totalSupply + expectedYield);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mDualBackedToOneDiffDecimals.balanceOf(yieldRecipient), expectedYield);
    }
}
