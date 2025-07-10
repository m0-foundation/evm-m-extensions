// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";

import { IAccessControl } from "../../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
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

    address constant WRAPPED_M = 0x437cc33344a0B27A429f795ff6B469C72698B291;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant UNIVERSAL_ROUTER = 0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af;

    SwapFacility public swapFacility;

    MockM public mToken;
    MockRegistrar public registrar;
    MockMExtension public extensionA;
    MockMExtension public extensionB;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    address[] public whitelistedTokens = new address[](2);

    function setUp() public {
        mToken = new MockM();
        registrar = new MockRegistrar();

        whitelistedTokens[0] = USDC;
        whitelistedTokens[1] = USDT;

        swapFacility = SwapFacility(
            UnsafeUpgrades.deployTransparentProxy(
                address(new SwapFacility(address(mToken), address(registrar), WRAPPED_M, UNIVERSAL_ROUTER)),
                owner,
                abi.encodeWithSelector(SwapFacility.initialize.selector, owner, whitelistedTokens)
            )
        );

        extensionA = new MockMExtension(address(mToken), address(swapFacility));
        extensionB = new MockMExtension(address(mToken), address(swapFacility));

        // Add Extensions to Earners List
        registrar.setEarner(address(extensionA), true);
        registrar.setEarner(address(extensionB), true);
        registrar.setEarner(WRAPPED_M, true);
    }

    function test_initialState() external {
        assertEq(swapFacility.mToken(), address(mToken));
        assertEq(swapFacility.registrar(), address(registrar));
        assertTrue(swapFacility.hasRole(swapFacility.DEFAULT_ADMIN_ROLE(), owner));
    }

    function test_constructor_zeroMToken() external {
        vm.expectRevert(ISwapFacility.ZeroMToken.selector);
        new SwapFacility(address(0), address(registrar), WRAPPED_M, UNIVERSAL_ROUTER);
    }

    function test_constructor_zeroRegistrar() external {
        vm.expectRevert(ISwapFacility.ZeroRegistrar.selector);
        new SwapFacility(address(mToken), address(0), WRAPPED_M, UNIVERSAL_ROUTER);
    }

    function test_constructor_zeroWrappedMToken() external {
        vm.expectRevert(ISwapFacility.ZeroWrappedMToken.selector);
        new SwapFacility(address(mToken), address(registrar), address(0), UNIVERSAL_ROUTER);
    }

    function test_constructor_zeroUniversalRouter() external {
        vm.expectRevert(ISwapFacility.ZeroUniversalRouter.selector);
        new SwapFacility(address(mToken), address(registrar), WRAPPED_M, address(0));
    }

    function test_swap() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.startPrank(alice);
        mToken.approve(address(swapFacility), amount);
        swapFacility.swapInM(address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);
        assertEq(extensionB.balanceOf(alice), 0);

        extensionA.approve(address(swapFacility), amount);

        vm.expectEmit(true, true, true, true);
        emit ISwapFacility.Swapped(address(extensionA), address(extensionB), amount, alice);

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

    function test_swapInM() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mToken.approve(address(swapFacility), amount);

        vm.expectEmit(true, true, true, true);
        emit ISwapFacility.SwappedInM(address(extensionA), amount, alice);

        vm.prank(alice);
        swapFacility.swapInM(address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);
    }

    function test_swapInM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swapInM(address(0x123), 1, alice);
    }

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

        vm.expectEmit(true, true, true, true);
        emit ISwapFacility.SwappedOutM(address(extensionA), amount, alice);

        swapFacility.swapOutM(address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), amount);
        assertEq(extensionA.balanceOf(alice), 0);
    }

    function test_swapOutM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swapOutM(address(0x123), 1, alice);
    }

    function test_swapOutM_notApprovedSwapper() external {
        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedSwapper.selector, alice));

        vm.prank(alice);
        swapFacility.swapOutM(address(extensionA), 1, alice);
    }

    function test_swapInToken_zeroAmount() public {
        vm.expectRevert(ISwapFacility.ZeroAmount.selector);
        swapFacility.swapInToken(USDC, 0, address(extensionA), 0, alice, "", block.timestamp);
    }

    function test_swapInToken_zeroRecipient() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(ISwapFacility.ZeroRecipient.selector);
        swapFacility.swapInToken(USDC, amountIn, address(extensionA), minAmountOut, address(0), "", block.timestamp);
    }

    function test_swapInToken_invalidPath() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        bytes memory path = abi.encodePacked(
            WRAPPED_M,
            uint24(100), // 0.01% fee
            USDC
        );

        vm.expectRevert(ISwapFacility.InvalidPath.selector);
        swapFacility.swapInToken(USDC, amountIn, address(extensionA), minAmountOut, alice, path, block.timestamp);
    }

    function test_swapInToken_invalidPathFormat() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(ISwapFacility.InvalidPathFormat.selector);
        swapFacility.swapInToken(USDC, amountIn, address(extensionA), minAmountOut, alice, "path", block.timestamp);
    }

    function test_swapInToken_notWhitelistedToken() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        address token = makeAddr("token");

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotWhitelistedToken.selector, token));
        swapFacility.swapInToken(token, amountIn, address(extensionA), minAmountOut, alice, "", block.timestamp);
    }

    function test_swapOutToken_zeroAmount() public {
        vm.expectRevert(ISwapFacility.ZeroAmount.selector);
        swapFacility.swapOutToken(WRAPPED_M, 0, USDC, 0, alice, "", block.timestamp);
    }

    function test_swapOutToken_zeroRecipient() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(ISwapFacility.ZeroRecipient.selector);
        swapFacility.swapOutToken(WRAPPED_M, amountIn, USDC, minAmountOut, address(0), "", block.timestamp);
    }

    function test_swapOutToken_invalidPath() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        bytes memory path = abi.encodePacked(
            USDC,
            uint24(100), // 0.01% fee
            WRAPPED_M
        );

        vm.expectRevert(ISwapFacility.InvalidPath.selector);
        swapFacility.swapOutToken(WRAPPED_M, amountIn, USDC, minAmountOut, alice, path, block.timestamp);
    }

    function test_swapOutToken_invalidPathFormat() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(ISwapFacility.InvalidPathFormat.selector);
        swapFacility.swapOutToken(WRAPPED_M, amountIn, USDC, minAmountOut, alice, "path", block.timestamp);
    }

    function test_swapOut_notWhitelistedToken() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        address token = makeAddr("token");

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotWhitelistedToken.selector, token));
        swapFacility.swapOutToken(WRAPPED_M, amountIn, token, minAmountOut, alice, "", block.timestamp);
    }

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
