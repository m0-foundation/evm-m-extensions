// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";

import { IAccessControl } from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { PausableUpgradeable } from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { ERC20 } from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { ISwapFacility } from "../../../src/swap/interfaces/ISwapFacility.sol";

import { SwapFacility } from "../../../src/swap/SwapFacility.sol";

import { MockERC20, MockM, MockJMIExtension, MockMExtension, MockRegistrar } from "../../utils/Mocks.sol";

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
    MockMExtension public extensionC;
    MockJMIExtension public jmiExtension;

    MockERC20 public mockUSDC;
    MockERC20 public mockDAI;

    address public owner = makeAddr("owner");
    address public pauser = makeAddr("pauser");
    address public alice = makeAddr("alice");

    function setUp() public {
        mToken = new MockM();
        registrar = new MockRegistrar();

        mockUSDC = new MockERC20("Mock USDC", "USDC", 6);
        mockDAI = new MockERC20("Mock DAI", "DAI", 18);

        swapFacility = SwapFacility(
            UnsafeUpgrades.deployTransparentProxy(
                address(new SwapFacility(address(mToken), address(registrar))),
                owner,
                abi.encodeWithSelector(SwapFacility.initialize.selector, owner, pauser)
            )
        );

        extensionA = new MockMExtension(address(mToken), address(swapFacility));
        extensionB = new MockMExtension(address(mToken), address(swapFacility));
        extensionC = new MockMExtension(address(mToken), address(swapFacility));
        jmiExtension = new MockJMIExtension(address(mToken), address(swapFacility), address(mockUSDC));

        // Add Extensions to Earners List
        registrar.setEarner(address(extensionA), true);
        registrar.setEarner(address(extensionB), true);
        registrar.setEarner(address(jmiExtension), true);

        // Set extension C as admin approved
        vm.prank(owner);
        swapFacility.setAdminApprovedExtension(address(extensionC), true);
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

    /* ============ canSwapViaPath ============ */

    // tokenIn == mToken
    function test_canSwapViaPath_tokenInIsMToken_notApprovedExtension() external {
        assertFalse(swapFacility.canSwapViaPath(alice, address(mToken), address(0x123)));
    }

    function test_canSwapViaPath_tokenInIsMToken_mSwapperRole() external {
        assertFalse(swapFacility.canSwapViaPath(alice, address(mToken), address(extensionA)));
        assertFalse(swapFacility.canSwapViaPath(alice, address(mToken), address(extensionC)));

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        assertTrue(swapFacility.canSwapViaPath(alice, address(mToken), address(extensionA)));
        assertTrue(swapFacility.canSwapViaPath(alice, address(mToken), address(extensionC)));
    }

    function test_canSwapViaPath_tokenInIsMToken_permissionedMSwapper() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        assertFalse(swapFacility.canSwapViaPath(alice, address(mToken), address(extensionA)));

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(address(extensionA), alice, true);

        assertTrue(swapFacility.canSwapViaPath(alice, address(mToken), address(extensionA)));
    }

    // tokenOut == mToken path
    function test_canSwapViaPath_tokenOutIsMToken_notApprovedExtension() external {
        assertFalse(swapFacility.canSwapViaPath(alice, address(0x123), address(mToken)));
    }

    function test_canSwapViaPath_tokenOutIsMToken_mSwapperRole() external {
        assertFalse(swapFacility.canSwapViaPath(alice, address(extensionA), address(mToken)));
        assertFalse(swapFacility.canSwapViaPath(alice, address(extensionC), address(mToken)));

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        assertTrue(swapFacility.canSwapViaPath(alice, address(extensionA), address(mToken)));
        assertTrue(swapFacility.canSwapViaPath(alice, address(extensionC), address(mToken)));
    }

    function test_canSwapViaPath_tokenOutIsMToken_permissionedMSwapper() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        assertFalse(swapFacility.canSwapViaPath(alice, address(extensionA), address(mToken)));

        vm.prank(owner);
        swapFacility.setPermissionedMSwapper(address(extensionA), alice, true);

        assertTrue(swapFacility.canSwapViaPath(alice, address(extensionA), address(mToken)));
    }

    // Both tokens being extensions
    function test_canSwapViaPath_extensionToExtension() external {
        address notApprovedExtension = address(0x123);

        // Approved extensions
        assertTrue(swapFacility.canSwapViaPath(alice, address(extensionA), address(extensionB)));

        // Admin approved extension
        assertTrue(swapFacility.canSwapViaPath(alice, address(extensionA), address(extensionC)));
        assertTrue(swapFacility.canSwapViaPath(alice, address(extensionC), address(extensionA)));

        assertFalse(swapFacility.canSwapViaPath(alice, notApprovedExtension, address(extensionA)));
        assertFalse(swapFacility.canSwapViaPath(alice, address(extensionA), notApprovedExtension));
    }

    function test_canSwapViaPath_extensionToExtension_tokenInPermissioned() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        assertFalse(swapFacility.canSwapViaPath(alice, address(extensionA), address(extensionB)));
    }

    function test_canSwapViaPath_extensionToExtension_tokenOutPermissioned() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionB), true);

        assertFalse(swapFacility.canSwapViaPath(alice, address(extensionA), address(extensionB)));
    }

    function test_canSwapViaPath_extensionToExtension_tokensPermissioned() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionB), true);

        assertFalse(swapFacility.canSwapViaPath(alice, address(extensionA), address(extensionB)));
    }

    // JMI path
    function test_canSwapViaPath_assetToJMIExtension() external {
        assertFalse(swapFacility.canSwapViaPath(alice, address(mockDAI), address(jmiExtension)));

        // mockUSDC is an allowed asset
        assertTrue(swapFacility.canSwapViaPath(alice, address(mockUSDC), address(jmiExtension)));

        // extensionA is not a JMI extension, so it doesn't support isAllowedAsset
        assertFalse(swapFacility.canSwapViaPath(alice, address(mockUSDC), address(extensionA)));
    }

    // Not extensions path
    function test_canSwapViaPath_notExtensions() external {
        // Can't swap between two non-extensions
        assertFalse(swapFacility.canSwapViaPath(alice, address(mockUSDC), address(mockDAI)));
    }

    /* ============ swap ============ */

    function test_swap_enforcedPause() external {
        vm.prank(pauser);
        swapFacility.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        swapFacility.swap(address(0x123), address(extensionA), 1_000, alice);
    }

    /* ============ swapExtensions ============ */

    function test_swapExtensions() external {
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

    function test_swapExtensions_adminApprovedExtension() external {
        uint256 amount = 1_000;

        extensionC.setBalanceOf(alice, amount);
        mToken.setBalanceOf(address(extensionC), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionC.balanceOf(alice), amount);
        assertEq(extensionA.balanceOf(alice), 0);

        vm.prank(alice);
        extensionC.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.Swapped(address(extensionC), address(extensionA), amount, alice);

        vm.prank(alice);
        swapFacility.swap(address(extensionC), address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionC.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);
    }

    function test_swapExtensions_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(
            abi.encodeWithSelector(ISwapFacility.InvalidSwapPath.selector, notApprovedExtension, address(extensionA))
        );

        swapFacility.swap(address(0x123), address(extensionA), 1_000, alice);

        vm.expectRevert(
            abi.encodeWithSelector(ISwapFacility.InvalidSwapPath.selector, address(extensionB), notApprovedExtension)
        );

        swapFacility.swap(address(extensionB), address(0x123), 1_000, alice);
    }

    function test_swapExtensions_permissionedExtension() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(extensionA)));

        swapFacility.swap(address(extensionA), address(extensionC), 1, alice);

        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionB), true);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(extensionB)));

        swapFacility.swap(address(extensionC), address(extensionB), 1, alice);
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
        swapFacility.swap(address(mToken), address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);
    }

    function test_swapInM_adminApprovedExtension() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        vm.prank(alice);
        mToken.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.SwappedInM(address(extensionC), amount, alice);

        vm.prank(alice);
        swapFacility.swap(address(mToken), address(extensionC), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionC.balanceOf(alice), amount);
    }

    function test_swapInM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swap(address(mToken), notApprovedExtension, 1, alice);
    }

    function test_swapInM_notApprovedPermissionedMSwapper() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        vm.expectRevert(
            abi.encodeWithSelector(ISwapFacility.NotApprovedPermissionedSwapper.selector, address(extensionA), alice)
        );

        vm.prank(alice);
        swapFacility.swap(address(mToken), address(extensionA), 1, alice);
    }

    function test_swapInM_notApprovedMSwapper() external {
        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedSwapper.selector, address(extensionA), alice));

        vm.prank(alice);
        swapFacility.swap(address(mToken), address(extensionA), 1, alice);
    }

    /* ============ swapInJMI ============ */

    function test_swapInJMI() external {
        uint256 amount = 1_000;

        mockUSDC.mint(alice, amount);
        assertEq(mockUSDC.balanceOf(alice), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(jmiExtension)), 0);

        assertEq(jmiExtension.balanceOf(alice), 0);

        vm.prank(alice);
        mockUSDC.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.SwappedInJMI(address(mockUSDC), address(jmiExtension), amount, alice);

        vm.prank(alice);
        swapFacility.swap(address(mockUSDC), address(jmiExtension), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(jmiExtension)), 0);

        assertEq(mockUSDC.balanceOf(alice), 0);
        assertEq(mockUSDC.balanceOf(address(jmiExtension)), amount);

        assertEq(jmiExtension.balanceOf(alice), amount);
    }

    function test_swapInJMI_extensionNotApproved() external {
        address notApprovedExtension = address(0x123);
        uint256 amount = 1_000;

        mockUSDC.mint(alice, amount);

        vm.prank(alice);
        mockUSDC.approve(address(swapFacility), amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISwapFacility.InvalidSwapPath.selector,
                address(mockUSDC),
                address(notApprovedExtension)
            )
        );

        vm.prank(alice);
        swapFacility.swap(address(mockUSDC), address(notApprovedExtension), amount, alice);
    }

    function test_swapInJMI_assetNotAllowed() external {
        uint256 amount = 1_000;

        mockDAI.mint(alice, amount);
        assertEq(mockDAI.balanceOf(alice), amount);

        vm.prank(alice);
        mockDAI.approve(address(swapFacility), amount);

        vm.expectRevert(
            abi.encodeWithSelector(ISwapFacility.InvalidSwapPath.selector, address(mockDAI), address(jmiExtension))
        );

        vm.prank(alice);
        swapFacility.swap(address(mockDAI), address(jmiExtension), amount, alice);
    }

    /* ============ swapOutM ============ */

    function test_swapOutM() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        vm.startPrank(alice);
        swapFacility.swap(address(mToken), address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);

        extensionA.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.SwappedOutM(address(extensionA), amount, alice);

        swapFacility.swap(address(extensionA), address(mToken), amount, alice);

        assertEq(mToken.balanceOf(alice), amount);
        assertEq(extensionA.balanceOf(alice), 0);
    }

    function test_swapOutM_adminApprovedExtension() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        vm.startPrank(alice);
        swapFacility.swap(address(mToken), address(extensionC), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionC.balanceOf(alice), amount);

        extensionC.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.SwappedOutM(address(extensionC), amount, alice);

        swapFacility.swap(address(extensionC), address(mToken), amount, alice);

        assertEq(mToken.balanceOf(alice), amount);
        assertEq(extensionC.balanceOf(alice), 0);
    }

    function test_swapOutM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swap(notApprovedExtension, address(mToken), 1, alice);
    }

    function test_swapOutM_notApprovedPermissionedMSwapper() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        vm.expectRevert(
            abi.encodeWithSelector(ISwapFacility.NotApprovedPermissionedSwapper.selector, address(extensionA), alice)
        );

        vm.prank(alice);
        swapFacility.swap(address(extensionA), address(mToken), 1, alice);
    }

    function test_swapOutM_notApprovedMSwapper() external {
        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedSwapper.selector, address(extensionA), alice));

        vm.prank(alice);
        swapFacility.swap(address(extensionA), address(mToken), 1, alice);
    }

    /* ============ replaceAssetWithM ============ */

    function test_replaceAssetWithM() external {
        uint256 amount = 1_000e6;

        extensionA.setBalanceOf(alice, amount);
        mToken.setBalanceOf(address(extensionA), amount);
        mockUSDC.mint(address(jmiExtension), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(extensionA)), amount);
        assertEq(mToken.balanceOf(address(jmiExtension)), 0);

        assertEq(extensionA.balanceOf(alice), amount);
        assertEq(jmiExtension.balanceOf(alice), 0);

        assertEq(mockUSDC.balanceOf(alice), 0);
        assertEq(mockUSDC.balanceOf(address(jmiExtension)), amount);

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        vm.prank(alice);
        mockUSDC.approve(address(swapFacility), amount);

        vm.prank(alice);
        extensionA.approve(address(swapFacility), amount);

        vm.expectEmit();
        emit ISwapFacility.JMIAssetReplaced(address(mockUSDC), address(jmiExtension), amount);

        vm.prank(alice);
        swapFacility.replaceAssetWithM(address(mockUSDC), address(extensionA), address(jmiExtension), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(extensionA)), 0);
        assertEq(mToken.balanceOf(address(jmiExtension)), amount);

        assertEq(extensionA.balanceOf(alice), 0);
        assertEq(jmiExtension.balanceOf(alice), 0);

        assertEq(mockUSDC.balanceOf(alice), amount);
        assertEq(mockUSDC.balanceOf(address(jmiExtension)), 0);
    }

    function test_replaceAssetWithM_enforcedPause() external {
        vm.prank(pauser);
        swapFacility.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(alice);
        swapFacility.replaceAssetWithM(address(mockUSDC), address(extensionA), address(jmiExtension), 1, alice);
    }

    function test_replaceAssetWithM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));

        vm.prank(alice);
        swapFacility.replaceAssetWithM(address(mockUSDC), notApprovedExtension, address(jmiExtension), 1, alice);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));

        vm.prank(alice);
        swapFacility.replaceAssetWithM(address(mockUSDC), address(extensionA), notApprovedExtension, 1, alice);
    }

    function test_replaceAssetWithM_permissionedExtension() external {
        vm.prank(owner);
        swapFacility.setPermissionedExtension(address(extensionA), true);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(extensionA)));

        vm.prank(alice);
        swapFacility.replaceAssetWithM(address(mockUSDC), address(extensionA), address(jmiExtension), 1, alice);
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

    /* ============ isMSwapper ============ */

    function test_isMSwapper() external {
        assertFalse(swapFacility.isMSwapper(alice));

        vm.prank(owner);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        assertTrue(swapFacility.isMSwapper(alice));
    }

    /* ============ isApprovedExtension ============ */

    function test_isApprovedExtension() external {
        assertTrue(swapFacility.isApprovedExtension(address(extensionA)));
        assertTrue(swapFacility.isApprovedExtension(address(extensionC)));

        vm.prank(owner);
        swapFacility.setAdminApprovedExtension(address(extensionC), false);
        registrar.setEarner(address(extensionA), false);

        assertFalse(swapFacility.isApprovedExtension(address(extensionA)));
        assertFalse(swapFacility.isApprovedExtension(address(extensionC)));
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

    /* ============ setAdminApprovedExtension =========== */

    function test_setAdminApprovedExtension_notAdmin_reverts() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                swapFacility.DEFAULT_ADMIN_ROLE()
            )
        );
        vm.prank(alice);
        swapFacility.setAdminApprovedExtension(address(extensionA), true);
    }

    function test_setAdminApprovedExtension_zeroAddress_reverts() external {
        vm.prank(owner);
        vm.expectRevert(ISwapFacility.ZeroExtension.selector);
        swapFacility.setAdminApprovedExtension(address(0), true);
    }

    function test_setAdminApprovedExtension_success() external {
        vm.prank(owner);
        swapFacility.setAdminApprovedExtension(address(extensionA), true);
        assertTrue(swapFacility.isAdminApprovedExtension(address(extensionA)));

        vm.prank(owner);
        swapFacility.setAdminApprovedExtension(address(extensionA), false);
        assertFalse(swapFacility.isAdminApprovedExtension(address(extensionA)));
    }
}
