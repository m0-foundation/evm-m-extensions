// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../../lib/common/src/interfaces/IERC20Extended.sol";

import {
    IAccessControl
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MockM } from "../../utils/Mocks.sol";

import { MDualBackedYieldToOne } from "../../../src/projects/dualBackedYieldToOne/MDualBackedYieldToOne.sol";
import { IMDualBackedYieldToOne } from "../../../src/projects/dualBackedYieldToOne/IMDualBackedYieldToOne.sol";
import { IMYieldToOne } from "../../../src/projects/yieldToOne/IMYieldToOne.sol";

import { IFreezable } from "../../../src/components/IFreezable.sol";
import { IMExtension } from "../../../src/interfaces/IMExtension.sol";

import { ISwapFacility } from "../../../src/swap/interfaces/ISwapFacility.sol";

import { MDualBackedYieldToOneHarness } from "../../harness/MDualBackedYieldToOneHarness.sol";

import { MockSecondaryBacker } from "../../utils/Mocks.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract MYDualBackedYieldToOneUnitTests is BaseUnitTest {
    MDualBackedYieldToOneHarness public mDualBackedToOne;

    string public constant NAME = "HALO USD";
    string public constant SYMBOL = "HALO USD";

    MockSecondaryBacker public secondary;

    function setUp() public override {
        super.setUp();

        secondary = new MockSecondaryBacker();

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

        registrar.setEarner(address(mDualBackedToOne), true);

        vm.prank(address(swapFacility));
        secondary.approve(address(mDualBackedToOne), type(uint256).max);
    }

    /* ============ initialize ============ */

    function test_initialize_dual() external view {
        assertEq(mDualBackedToOne.name(), NAME);
        assertEq(mDualBackedToOne.symbol(), SYMBOL);
        assertEq(mDualBackedToOne.decimals(), 6);
        assertEq(mDualBackedToOne.mToken(), address(mToken));
        assertEq(mDualBackedToOne.swapFacility(), address(swapFacility));
        assertEq(mDualBackedToOne.yieldRecipient(), yieldRecipient);

        assertTrue(IAccessControl(address(mDualBackedToOne)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(
            IAccessControl(address(mDualBackedToOne)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager)
        );
    }

    function test_initialize_zeroYieldRecipient_dual() external {
        address implementation = address(new MDualBackedYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipient.selector);
        MDualBackedYieldToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedYieldToOneHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(0),
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    address(secondary)
                )
            )
        );
    }

    function test_initialize_zeroAdmin() external {
        address implementation = address(new MDualBackedYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroAdmin.selector);
        MDualBackedYieldToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedYieldToOneHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    yieldRecipient,
                    address(0),
                    freezeManager,
                    yieldRecipientManager,
                    address(secondary)
                )
            )
        );
    }

    function test_initialize_zeroYieldRecipientManager() external {
        address implementation = address(new MDualBackedYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipientManager.selector);
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
                    address(0),
                    address(secondary)
                )
            )
        );
    }

    /* ============ _wrapSecondary ============ */

    function test_wrap_secondary() public {
        uint256 amount = 1_000e6;
        uint256 secondaryAmount = amount;
        secondary.mint(address(swapFacility), secondaryAmount);

        vm.expectCall(
            address(secondary),
            abi.encodeWithSelector(
                secondary.transferFrom.selector,
                address(swapFacility),
                address(mDualBackedToOne),
                secondaryAmount
            )
        );

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, amount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrapSecondary(alice, amount);

        assertEq(mDualBackedToOne.balanceOf(alice), amount);
        assertEq(mDualBackedToOne.totalSupply(), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(secondary.balanceOf(address(mDualBackedToOne)), secondaryAmount);
    }

    /* ============ _unwrap ============ */

    function test_unwrap_with_only_secondary_backing() public {
        uint256 amount = 1_000e6;
        uint256 secondaryAmount = amount;

        mDualBackedToOne.setBalanceOf(address(swapFacility), amount);
        mDualBackedToOne.setBalanceOf(alice, amount);
        mDualBackedToOne.setTotalSupply(amount);
        mDualBackedToOne.setSecondarySupply(amount);

        secondary.mint(address(mDualBackedToOne), secondaryAmount);

        vm.expectRevert(abi.encodeWithSelector(IMDualBackedYieldToOne.InsufficientMBacking.selector));

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 1e6);
    }

    function test_unwrap_with_secondary_backing() public {
        uint256 amount = 1_000e6;
        uint256 secondaryAmount = amount;

        mDualBackedToOne.setBalanceOf(address(swapFacility), 2 * amount);
        mDualBackedToOne.setTotalSupply(2 * amount);
        mDualBackedToOne.setSecondarySupply(amount);

        mToken.setBalanceOf(address(mDualBackedToOne), amount);
        secondary.mint(address(mDualBackedToOne), secondaryAmount);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 1e6);

        assertEq(mDualBackedToOne.totalSupply(), 999e6 + amount);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 999e6 + amount);
        assertEq(mToken.balanceOf(address(swapFacility)), 1e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 499e6);

        assertEq(mDualBackedToOne.totalSupply(), 500e6 + amount);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 500e6 + amount);
        assertEq(mToken.balanceOf(address(swapFacility)), 500e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 500e6);

        assertEq(mDualBackedToOne.totalSupply(), 0 + amount);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 0 + amount);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), amount);
        assertEq(mToken.balanceOf(address(mDualBackedToOne)), 0);
    }

    /* ============ yield ============ */

    function testFuzz_yield_withSecondary(uint256 mBalance, uint256 secondarySupply, uint256 totalSupply) external {
        mBalance = bound(mBalance, 0, type(uint128).max);
        secondarySupply = bound(secondarySupply, 0, type(uint128).max);
        totalSupply = bound(totalSupply, 0, mBalance + secondarySupply);

        if (totalSupply < secondarySupply) secondarySupply = totalSupply;

        mToken.setBalanceOf(address(mDualBackedToOne), mBalance);
        mDualBackedToOne.setSecondarySupply(secondarySupply);
        mDualBackedToOne.setTotalSupply(totalSupply);

        assertEq(mDualBackedToOne.yield(), mBalance - (totalSupply - secondarySupply));
    }

    /* ============ claimYield ============ */
    function test_claimYield_withSecondary() external {
        uint256 yield = 500e6;

        secondary.mint(address(mDualBackedToOne), 1_500e6);
        mToken.setBalanceOf(address(mDualBackedToOne), 1_500e6);
        mDualBackedToOne.setTotalSupply(2_500e6);
        mDualBackedToOne.setSecondarySupply(1_500e6);

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
}
