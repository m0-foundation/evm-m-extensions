// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";

import { IAccessControl } from "../../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { IUniswapV3SwapAdapter } from "../../../src/swap/interfaces/IUniswapV3SwapAdapter.sol";
import { UniswapV3SwapAdapter } from "../../../src/swap/UniswapV3SwapAdapter.sol";

import { MockM, MockMExtension } from "../../utils/Mocks.sol";

contract UniswapV3SwapAdapterUnitTests is Test {
    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant UNISWAP_V3_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    address public swapFacility = makeAddr("swapFacility");

    MockMExtension public wrappedM;
    UniswapV3SwapAdapter public swapAdapter;
    address[] public whitelistedToken = new address[](2);

    function setUp() public {
        whitelistedToken[0] = USDC;
        whitelistedToken[1] = USDT;

        wrappedM = new MockMExtension(address(new MockM()), swapFacility);

        swapAdapter = new UniswapV3SwapAdapter(
            address(wrappedM),
            swapFacility,
            UNISWAP_V3_ROUTER,
            admin,
            whitelistedToken
        );
    }

    function test_initialState() public {
        assertEq(swapAdapter.wrappedMToken(), address(wrappedM));
        assertEq(swapAdapter.swapFacility(), swapFacility);
        assertEq(swapAdapter.uniswapRouter(), UNISWAP_V3_ROUTER);
        assertTrue(swapAdapter.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(swapAdapter.whitelistedToken(USDC));
        assertTrue(swapAdapter.whitelistedToken(USDT));
    }

    function test_constructor_zeroWrappedMToken() external {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroWrappedMToken.selector);
        new UniswapV3SwapAdapter(address(0), swapFacility, UNISWAP_V3_ROUTER, admin, whitelistedToken);
    }

    function test_constructor_zerSwapFacility() external {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroSwapFacility.selector);
        new UniswapV3SwapAdapter(address(wrappedM), address(0), UNISWAP_V3_ROUTER, admin, whitelistedToken);
    }

    function test_constructor_zeroUniswapRouter() external {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroUniswapRouter.selector);
        new UniswapV3SwapAdapter(address(wrappedM), swapFacility, address(0), admin, whitelistedToken);
    }

    function test_whitelistToken() external {
        address newToken = makeAddr("newToken");
        vm.prank(admin);
        swapAdapter.whitelistToken(newToken, true);

        assertTrue(swapAdapter.whitelistedToken(newToken));

        vm.prank(admin);
        swapAdapter.whitelistToken(newToken, false);

        assertFalse(swapAdapter.whitelistedToken(newToken));
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
        swapAdapter.swapIn(USDC, 0, address(wrappedM), 0, alice, "");
    }

    function test_swapIn_zeroRecipient() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.ZeroRecipient.selector);
        swapAdapter.swapIn(USDC, amountIn, address(wrappedM), minAmountOut, address(0), "");
    }

    function test_swapIn_invalidPath() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        bytes memory path = abi.encodePacked(address(wrappedM), uint24(100), USDC);

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPath.selector);
        swapAdapter.swapIn(USDC, amountIn, address(wrappedM), minAmountOut, alice, path);
    }

    function test_swapIn_invalidPathFormat() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPathFormat.selector);
        swapAdapter.swapIn(USDC, amountIn, address(wrappedM), minAmountOut, alice, "invalidPath");
    }

    function test_swapIn_notWhitelistedToken() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        address token = makeAddr("token");

        vm.expectRevert(abi.encodeWithSelector(IUniswapV3SwapAdapter.NotWhitelistedToken.selector, token));
        swapAdapter.swapIn(token, amountIn, address(wrappedM), minAmountOut, alice, "");
    }

    function test_swapOut_zeroAmount() public {
        vm.expectRevert(IUniswapV3SwapAdapter.ZeroAmount.selector);
        swapAdapter.swapOut(address(wrappedM), 0, USDC, 0, alice, "");
    }

    function test_swapOut_zeroRecipient() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.ZeroRecipient.selector);
        swapAdapter.swapOut(address(wrappedM), amountIn, USDC, minAmountOut, address(0), "");
    }

    function test_swapOut_invalidPath() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        bytes memory path = abi.encodePacked(USDC, uint24(100), address(wrappedM));

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPath.selector);
        swapAdapter.swapOut(address(wrappedM), amountIn, USDC, minAmountOut, alice, path);
    }

    function test_swapOut_invalidPathFormat() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.expectRevert(IUniswapV3SwapAdapter.InvalidPathFormat.selector);
        swapAdapter.swapOut(address(wrappedM), amountIn, USDC, minAmountOut, alice, "invalidPath");
    }

    function test_swapOut_notWhitelistedToken() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        address token = makeAddr("token");

        vm.expectRevert(abi.encodeWithSelector(IUniswapV3SwapAdapter.NotWhitelistedToken.selector, token));
        swapAdapter.swapOut(address(wrappedM), amountIn, token, minAmountOut, alice, "");
    }
}
