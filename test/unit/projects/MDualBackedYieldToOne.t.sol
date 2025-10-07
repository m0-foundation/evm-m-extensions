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

import { IMExtension } from "../../../src/interfaces/IMExtension.sol";

import { MDualBackedYieldToOneHarness } from "../../harness/MDualBackedYieldToOneHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract MYDualBackedYieldToOneUnitTests is BaseUnitTest {
    MDualBackedYieldToOneHarness public mDualBackedToOne;
    MDualBackedYieldToOneHarness public mDualBackedToOne4Decimals;
    MDualBackedYieldToOneHarness public mDualBackedToOne18Decimals;

    string public constant NAME = "M Dual Backed Yield to One";
    string public constant SYMBOL = "MDBYO";

    MockERC20 public secondary;
    MockERC20 public secondary4Decimals;
    MockERC20 public secondary18Decimals;

    function setUp() public override {
        super.setUp();

        secondary = new MockERC20("MockSecondaryToken", "MST", 6);
        secondary4Decimals = new MockERC20("MockSecondaryToken4", "MST4", 4);
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

        mDualBackedToOne4Decimals = MDualBackedYieldToOneHarness(
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
                    address(secondary4Decimals)
                ),
                mExtensionDeployOptions
            )
        );

        mDualBackedToOne18Decimals = MDualBackedYieldToOneHarness(
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
        registrar.setEarner(address(mDualBackedToOne4Decimals), true);
        registrar.setEarner(address(mDualBackedToOne18Decimals), true);

        vm.prank(address(swapFacility));
        secondary.approve(address(mDualBackedToOne), type(uint256).max);

        vm.prank(address(swapFacility));
        secondary4Decimals.approve(address(mDualBackedToOne4Decimals), type(uint256).max);

        vm.prank(address(swapFacility));
        secondary18Decimals.approve(address(mDualBackedToOne18Decimals), type(uint256).max);
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

    function test_initialize_secondaryToken4Decimals() external {
        assertEq(mDualBackedToOne4Decimals.secondaryDecimals(), 4);
        assertEq(mDualBackedToOne4Decimals.secondaryToken(), address(secondary4Decimals));
    }

    function test_initialize_secondaryToken18Decimals() external {
        assertEq(mDualBackedToOne18Decimals.secondaryDecimals(), 18);
        assertEq(mDualBackedToOne18Decimals.secondaryToken(), address(secondary18Decimals));
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

        secondary18Decimals.mint(address(mDualBackedToOne18Decimals), secondaryAmount);
        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOne18Decimals)), secondaryAmount);

        vm.expectEmit();
        emit IERC20.Transfer(address(mDualBackedToOne18Decimals), alice, secondaryAmount);

        vm.expectEmit();
        emit IMDualBackedYieldToOne.SwappedSecondaryToken(address(secondary18Decimals), secondaryAmount);

        vm.prank(address(swapFacility));
        mDualBackedToOne18Decimals.swapSecondary(alice, secondaryAmount);

        assertEq(mDualBackedToOne18Decimals.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 0);

        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOne18Decimals)), 0);
        assertEq(secondary18Decimals.balanceOf(alice), secondaryAmount);
    }

    function testFuzz_swapSecondary(uint240 amount) public {
        mToken.setBalanceOf(address(swapFacility), amount);
        assertEq(mToken.balanceOf(address(swapFacility)), amount);

        secondary.mint(address(mDualBackedToOne), amount);
        assertEq(secondary.balanceOf(address(mDualBackedToOne)), amount);

        if (amount == 0) {
            vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(address(mDualBackedToOne), alice, amount);

            vm.expectEmit();
            emit IMDualBackedYieldToOne.SwappedSecondaryToken(address(secondary), amount);
        }

        vm.prank(address(swapFacility));
        mDualBackedToOne.swapSecondary(alice, amount);

        assertEq(mDualBackedToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 0);

        assertEq(secondary.balanceOf(address(mDualBackedToOne)), 0);
        assertEq(secondary.balanceOf(alice), amount);
    }

    function testFuzz_swapSecondary_diffDecimals(uint240 amount) public {
        uint256 extensionAmount = mDualBackedToOne18Decimals.toExtensionAmount(amount);
        uint256 expectedTransferAmount = mDualBackedToOne18Decimals.toSecondaryAmount(extensionAmount);

        mToken.setBalanceOf(address(swapFacility), extensionAmount);
        assertEq(mToken.balanceOf(address(swapFacility)), extensionAmount);

        secondary18Decimals.mint(address(mDualBackedToOne18Decimals), amount);
        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOne18Decimals)), amount);

        if (amount == 0) {
            vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(address(mDualBackedToOne18Decimals), alice, expectedTransferAmount);

            vm.expectEmit();
            emit IMDualBackedYieldToOne.SwappedSecondaryToken(address(secondary18Decimals), amount);
        }

        vm.prank(address(swapFacility));
        mDualBackedToOne18Decimals.swapSecondary(alice, amount);

        assertEq(mDualBackedToOne18Decimals.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 0);

        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOne18Decimals)), amount - expectedTransferAmount);

        assertEq(secondary18Decimals.balanceOf(alice), expectedTransferAmount);
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
        mDualBackedToOne18Decimals.wrapSecondary(alice, secondaryAmount);

        assertEq(mDualBackedToOne18Decimals.balanceOf(alice), extensionAmount);
        assertEq(mDualBackedToOne18Decimals.totalSupply(), extensionAmount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(secondary18Decimals.balanceOf(address(mDualBackedToOne18Decimals)), secondaryAmount);
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

    function testFuzz_yield(uint240 mBalance, uint240 secondarySupply) external {
        uint256 totalSupply = uint256(mBalance) + secondarySupply;
        totalSupply = bound(totalSupply, 0, totalSupply > type(uint240).max ? type(uint240).max : totalSupply);

        mToken.setBalanceOf(address(mDualBackedToOne), mBalance);
        secondary.mint(address(mDualBackedToOne), secondarySupply);
        mDualBackedToOne.setTotalSupply(totalSupply);

        uint240 mBacking = totalSupply < secondarySupply ? 0 : uint240(totalSupply) - secondarySupply;

        assertEq(mDualBackedToOne.yield(), mBalance > mBacking ? mBalance - mBacking : 0);
    }

    function testFuzz_yield_diffDecimals(uint240 mBalance, uint240 secondarySupply) external {
        uint256 totalSupply = uint256(mBalance) + secondarySupply;
        totalSupply = bound(totalSupply, 0, totalSupply > type(uint240).max ? type(uint240).max : totalSupply);

        mToken.setBalanceOf(address(mDualBackedToOne18Decimals), mBalance);
        secondary18Decimals.mint(address(mDualBackedToOne18Decimals), secondarySupply);
        mDualBackedToOne18Decimals.setTotalSupply(totalSupply);

        if (secondarySupply > 0)
            secondarySupply = uint240(mDualBackedToOne18Decimals.toExtensionAmount(secondarySupply));

        uint240 mBacking = totalSupply < secondarySupply ? 0 : uint240(totalSupply) - secondarySupply;

        assertEq(mDualBackedToOne18Decimals.yield(), mBalance > mBacking ? mBalance - mBacking : 0);
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

        secondary18Decimals.mint(address(mDualBackedToOne18Decimals), secondarySupply);
        mToken.setBalanceOf(address(mDualBackedToOne18Decimals), mBalance);
        mDualBackedToOne18Decimals.setTotalSupply(totalSupply);

        assertEq(mDualBackedToOne18Decimals.yield(), expectedYield);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(expectedYield);

        assertEq(mDualBackedToOne18Decimals.claimYield(), expectedYield);
        assertEq(mDualBackedToOne18Decimals.yield(), 0);

        assertEq(mToken.balanceOf(address(mDualBackedToOne18Decimals)), mBalance);
        assertEq(mDualBackedToOne18Decimals.totalSupply(), totalSupply + expectedYield);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mDualBackedToOne18Decimals.balanceOf(yieldRecipient), expectedYield);
    }

    /* ============ _toExtensionAmount ============ */

    function testFuzz_toExtensionAmount_lessDecimals(uint240 amount) external {
        uint256 scaleFactor = 10 ** 2;

        if (uint256(amount) > type(uint256).max / scaleFactor) {
            assertEq(mDualBackedToOne4Decimals.toExtensionAmount(amount), type(uint256).max);
        } else {
            assertEq(mDualBackedToOne4Decimals.toExtensionAmount(amount), uint256(amount) * scaleFactor);
        }
    }

    function testFuzz_toExtensionAmount_sameDecimals(uint240 amount) external {
        assertEq(mDualBackedToOne.toExtensionAmount(amount), amount);
    }

    function testFuzz_toExtensionAmount_moreDecimals(uint240 amount) external {
        assertEq(mDualBackedToOne18Decimals.toExtensionAmount(amount), uint256(amount) / 10 ** 12);
    }

    /* ============ _toSecondaryAmount ============ */

    function testFuzz_toSecondaryAmount_lessDecimals(uint240 amount) external {
        assertEq(mDualBackedToOne4Decimals.toSecondaryAmount(amount), uint256(amount) / 10 ** 2);
    }

    function testFuzz_toSecondaryAmount_sameDecimals(uint240 amount) external {
        assertEq(mDualBackedToOne.toSecondaryAmount(amount), amount);
    }

    function testFuzz_toSecondaryAmount_moreDecimals(uint240 amount) external {
        uint256 scaleFactor = 10 ** 12;

        if (uint256(amount) > type(uint256).max / scaleFactor) {
            assertEq(mDualBackedToOne18Decimals.toSecondaryAmount(amount), type(uint256).max);
        } else {
            assertEq(mDualBackedToOne18Decimals.toSecondaryAmount(amount), uint256(amount) * scaleFactor);
        }
    }
}
