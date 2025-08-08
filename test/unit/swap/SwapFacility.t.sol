// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";

import {
    IAccessControl
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { ISwapFacility } from "../../../src/swap/interfaces/ISwapFacility.sol";

import { SwapFacility } from "../../../src/swap/SwapFacility.sol";

import { MockM, MockMExtension, MockRegistrar } from "../../utils/Mocks.sol";

contract SwapFacilityV2 {
    function foo() external pure returns (uint256) {
        return 1;
    }
}

contract SwapFacilityUnitTests is Test {
    bytes32 public constant M_SWAPPER_ROLE = keccak256("M_SWAPPER_ROLE");

    SwapFacility public swapFacility;

    MockM public mToken;
    MockRegistrar public registrar;
    MockMExtension public extensionA;
    MockMExtension public extensionB;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    function setUp() public {
        mToken = new MockM();
        registrar = new MockRegistrar();

        swapFacility = SwapFacility(
            UnsafeUpgrades.deployTransparentProxy(
                address(new SwapFacility(address(mToken), address(registrar))),
                owner,
                abi.encodeWithSelector(SwapFacility.initialize.selector, owner)
            )
        );

        extensionA = new MockMExtension(address(mToken), address(swapFacility));
        extensionB = new MockMExtension(address(mToken), address(swapFacility));

        // Add Extensions to Earners List
        registrar.setEarner(address(extensionA), true);
        registrar.setEarner(address(extensionB), true);
    }

    /* ============ initialize ============ */

    function test_initialState() external {
        assertEq(swapFacility.mToken(), address(mToken));
        assertEq(swapFacility.registrar(), address(registrar));
        assertTrue(swapFacility.hasRole(swapFacility.DEFAULT_ADMIN_ROLE(), owner));
    }

    function test_constructor_zeroMToken() external {
        vm.expectRevert(ISwapFacility.ZeroMToken.selector);
        new SwapFacility(address(0), address(registrar));
    }

    function test_constructor_zeroRegistrar() external {
        vm.expectRevert(ISwapFacility.ZeroRegistrar.selector);
        new SwapFacility(address(mToken), address(0));
    }

    /* ============ swap ============ */

    function test_swap() external {
        uint256 amount = 1_000;

        extensionA.setBalanceOf(alice, amount);
        mToken.setBalanceOf(address(extensionA), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);
        assertEq(extensionB.balanceOf(alice), 0);

        vm.prank(alice);
        extensionA.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.Swapped(address(extensionA), address(extensionB), amount, alice);

        vm.prank(alice);
        swapFacility.swap(address(extensionA), address(extensionB), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), 0);
        assertEq(extensionB.balanceOf(alice), amount);
    }

    function test_swap_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swap(address(0x123), address(extensionA), 1_000, alice);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swap(address(extensionB), address(0x123), 1_000, alice);
    }

    /* ============ swapInM ============ */

    function test_swapInM() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        vm.prank(alice);
        mToken.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.SwappedInM(address(extensionA), amount, alice);

        vm.prank(alice);
        swapFacility.swapInM(address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);
    }

    function test_swapInM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swapInM(notApprovedExtension, 1, alice);
    }

    function test_swapInM_notApprovedPermissionedMSwapper() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        vm.expectRevert(
            abi.encodeWithSelector(ISwapFacility.NotApprovedPermissionedSwapper.selector, address(extensionA), alice)
        );

        vm.prank(alice);
        swapFacility.swapInM(address(extensionA), 1, alice);
    }

    function test_swapInM_notApprovedMSwapper() external {
        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedSwapper.selector, address(extensionA), alice));

        vm.prank(alice);
        swapFacility.swapInM(address(extensionA), 1, alice);
    }

    /* ============ swapOutM ============ */

    function test_swapOutM() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        vm.startPrank(alice);
        swapFacility.swapInM(address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);

        extensionA.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.SwappedOutM(address(extensionA), amount, alice);

        swapFacility.swapOutM(address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), amount);
        assertEq(extensionA.balanceOf(alice), 0);
    }

    function test_swapOutM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swapOutM(notApprovedExtension, 1, alice);
    }

    function test_swapOutM_notApprovedPermissionedMSwapper() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        vm.expectRevert(
            abi.encodeWithSelector(ISwapFacility.NotApprovedPermissionedSwapper.selector, address(extensionA), alice)
        );

        vm.prank(alice);
        swapFacility.swapOutM(address(extensionA), 1, alice);
    }

    function test_swapOutM_notApprovedMSwapper() external {
        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedSwapper.selector, address(extensionA), alice));

        vm.prank(alice);
        swapFacility.swapOutM(address(extensionA), 1, alice);
    }

    /* ============ setPermissionedExtension ============ */

    function test_setPermissionedExtension() external {
        address extension = address(0x123);
        bool permission = true;

        vm.expectEmit();
        emit ISwapFacility.PermissionedExtensionSet(extension, permission);

        vm.prank(owner);
        swapFacility.setPermissionedExtension(extension, permission);

        assertTrue(swapFacility.isPermissionedExtension(extension));

        vm.prank(owner);

        // Return early if already permissioned
        swapFacility.setPermissionedExtension(extension, permission);

        assertTrue(swapFacility.isPermissionedExtension(extension));
    }

    function test_setPermissionedExtension_removeExtensionFromPermissionedList() external {
        address extension = address(0x123);

        vm.prank(owner);
        swapFacility.setPermissionedExtension(extension, true);

        assertTrue(swapFacility.isPermissionedExtension(extension));

        vm.prank(owner);
        swapFacility.setPermissionedExtension(extension, false);

        assertFalse(swapFacility.isPermissionedExtension(extension));
    }

    function test_setPermissionedExtension_notAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                swapFacility.DEFAULT_ADMIN_ROLE()
            )
        );

        vm.prank(alice);
        swapFacility.setPermissionedExtension(address(0x123), true);
    }

    function test_setPermissionedExtension_zeroAddress() external {
        vm.expectRevert(ISwapFacility.ZeroExtension.selector);

        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(0), true);
    }

    /* ============ setPermissionedMSwapper ============ */

    function test_setPermissionedMSwapper() external {
        address extension = address(0x123);
        address swapper = address(0x456);
        bool allowed = true;

        vm.expectEmit();
        emit ISwapFacility.PermissionedMSwapperSet(extension, swapper, allowed);

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(extension, swapper, allowed);

        assertTrue(swapFacility.isPermissionedMSwapper(extension, swapper));

        vm.prank(owner);

        // Return early if already permissioned
        swapFacility.setPermissionedMSwapper(extension, swapper, allowed);

        assertTrue(swapFacility.isPermissionedMSwapper(extension, swapper));
    }

    function test_setPermissionedMSwapper_removeSwapperFromPermissionedList() external {
        address extension = address(0x123);
        address swapper = address(0x456);

        vm.expectEmit();
        emit ISwapFacility.PermissionedMSwapperSet(extension, swapper, true);

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(extension, swapper, true);

        assertTrue(swapFacility.isPermissionedMSwapper(extension, swapper));

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(extension, swapper, false);

        assertFalse(swapFacility.isPermissionedMSwapper(extension, swapper));
    }

    function test_setPermissionedMSwapper_notAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                swapFacility.DEFAULT_ADMIN_ROLE()
            )
        );

        vm.prank(alice);
        swapFacility.setPermissionedMSwapper(address(0x123), address(0x456), true);
    }

    function test_setPermissionedMSwapper_zeroExtension() external {
        vm.expectRevert(ISwapFacility.ZeroExtension.selector);

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(address(0), address(0x456), true);
    }

    function test_setPermissionedMSwapper_zeroSwapper() external {
        vm.expectRevert(ISwapFacility.ZeroSwapper.selector);

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(address(0x123), address(0), true);
    }

    /* ============ isPermissionedExtension ============ */

    function test_isPermissionedExtension() external {
        address extension = address(0x123);
        assertFalse(swapFacility.isPermissionedExtension(extension));

        vm.prank(owner);
        swapFacility.setPermissionedExtension(extension, true);

        assertTrue(swapFacility.isPermissionedExtension(extension));
    }

    /* ============ isPermissionedMSwapper ============ */

    function test_isPermissionedMSwapper() external {
        address extension = address(0x123);
        address swapper = address(0x456);

        assertFalse(swapFacility.isPermissionedMSwapper(extension, swapper));

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(extension, swapper, true);

        assertTrue(swapFacility.isPermissionedMSwapper(extension, swapper));
    }

    /* ============ upgrade ============ */

    function test_upgrade() external {
        // Current version does not have foo() function
        vm.expectRevert();
        SwapFacilityV2(address(swapFacility)).foo();

        // Upgrade the contract to a new implementation
        vm.startPrank(owner);
        UnsafeUpgrades.upgradeProxy(address(swapFacility), address(new SwapFacilityV2()), "");

        // Verify the upgrade was successful
        assertEq(SwapFacilityV2(address(swapFacility)).foo(), 1);
    }
}
