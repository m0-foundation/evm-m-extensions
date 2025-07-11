// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";

import { IAccessControl } from "../../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { IUniswapV3SwapAdapter } from "../../../src/swap/interfaces/IUniswapV3SwapAdapter.sol";
import { UniswapV3SwapAdapter } from "../../../src/swap/UniswapV3SwapAdapter.sol";

contract UniswapV3SwapAdapterUnitTests is Test {
    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    address constant WRAPPED_M = 0x437cc33344a0B27A429f795ff6B469C72698B291;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant UNISWAP_V3_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    address public swapFacility = makeAddr("swapFacility");

    UniswapV3SwapAdapter public swapAdapter;
    address[] public whitelistedTokens = new address[](2);

    function setUp() public {
        whitelistedTokens[0] = USDC;
        whitelistedTokens[1] = USDT;

        swapAdapter = new UniswapV3SwapAdapter(WRAPPED_M, swapFacility, UNISWAP_V3_ROUTER, admin, whitelistedTokens);
    }

    function test_initialState() public {
        assertEq(swapAdapter.wrappedMToken(), WRAPPED_M);
        assertEq(swapAdapter.swapFacility(), swapFacility);
        assertEq(swapAdapter.swapRouter(), UNISWAP_V3_ROUTER);
        assertTrue(swapAdapter.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(swapAdapter.whitelistedTokens(USDC));
        assertTrue(swapAdapter.whitelistedTokens(USDT));
    }

    function test_constructor_zeroWrappedMToken() external {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroWrappedMToken.selector);
        new UniswapV3SwapAdapter(address(0), swapFacility, UNISWAP_V3_ROUTER, admin, whitelistedTokens);
    }

    function test_constructor_zerSwapFacility() external {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroSwapFacility.selector);
        new UniswapV3SwapAdapter(WRAPPED_M, address(0), UNISWAP_V3_ROUTER, admin, whitelistedTokens);
    }

    function test_constructor_zeroSwapAdapter() external {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroSwapRouter.selector);
        new UniswapV3SwapAdapter(WRAPPED_M, swapFacility, address(0), admin, whitelistedTokens);
    }

    function test_whitelistToken() external {
        address newToken = makeAddr("newToken");
        vm.prank(admin);
        swapAdapter.whitelistToken(newToken, true);

        assertTrue(swapAdapter.whitelistedTokens(newToken));

        vm.prank(admin);
        swapAdapter.whitelistToken(newToken, false);

        assertFalse(swapAdapter.whitelistedTokens(newToken));
    }

    function test_whitelistToken_nonAdmin() external {
        address newToken = makeAddr("newToken");
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        vm.prank(alice);
        swapAdapter.whitelistToken(newToken, true);
    }

    function test_swapIn_zeroAmount() public {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroAmount.selector);
        swapAdapter.swapIn(USDC, 0, WRAPPED_M, 0, alice, "");
    }

    function test_swapIn_zeroRecipient() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.ZeroRecipient.selector);
        swapAdapter.swapIn(USDC, amountIn, WRAPPED_M, minAmountOut, address(0), "");
    }

    function test_swapIn_invalidPath() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        bytes memory path = abi.encodePacked(
            WRAPPED_M,
            uint24(100), // 0.01% fee
            USDC
        );

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPath.selector);
        swapAdapter.swapIn(WRAPPED_M, amountIn, WRAPPED_M, minAmountOut, alice, path);
    }

    function test_swapIn_invalidPathFormat() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPathFormat.selector);
        swapAdapter.swapIn(USDC, amountIn, WRAPPED_M, minAmountOut, alice, "invalidPath");
    }

    function test_swapIn_notWhitelistedToken() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        address token = makeAddr("token");

        vm.expectRevert(abi.encodeWithSelector(IUniswapV3SwapAdapter.NotWhitelistedToken.selector, token));
        swapAdapter.swapIn(token, amountIn, WRAPPED_M, minAmountOut, alice, "");
    }

    function test_swapOut_zeroAmount() public {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroAmount.selector);
        swapAdapter.swapOut(WRAPPED_M, 0, USDC, 0, alice, "");
    }

    function test_swapOut_zeroRecipient() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.ZeroRecipient.selector);
        swapAdapter.swapOut(WRAPPED_M, amountIn, USDC, minAmountOut, address(0), "");
    }

    function test_swapOut_invalidPath() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        bytes memory path = abi.encodePacked(
            USDC,
            uint24(100), // 0.01% fee
            WRAPPED_M
        );

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPath.selector);
        swapAdapter.swapOut(WRAPPED_M, amountIn, USDC, minAmountOut, alice, path);
    }

    function test_swapOut_invalidPathFormat() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPathFormat.selector);
        swapAdapter.swapOut(WRAPPED_M, amountIn, USDC, minAmountOut, alice, "invalidPath");
    }

    function test_swapOut_notWhitelistedToken() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        address token = makeAddr("token");

        vm.expectRevert(abi.encodeWithSelector(IUniswapV3SwapAdapter.NotWhitelistedToken.selector, token));
        swapAdapter.swapOut(WRAPPED_M, amountIn, token, minAmountOut, alice, "");
    }
}
