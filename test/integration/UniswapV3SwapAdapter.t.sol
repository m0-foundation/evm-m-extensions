// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import { WrappedMToken } from "../../lib/wrapped-m-token/src/WrappedMToken.sol";
import { EarnerManager } from "../../lib/wrapped-m-token/src/EarnerManager.sol";
import { WrappedMTokenMigratorV1 } from "../../lib/wrapped-m-token/src/WrappedMTokenMigratorV1.sol";
import { Proxy } from "../../lib/common/src/Proxy.sol";

import { IBlacklistable } from "../../src/components/IBlacklistable.sol";

import { MYieldToOneHarness } from "../harness/MYieldToOneHarness.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract UniswapV3SwapAdapterIntegrationTest is BaseIntegrationTest {
    using SafeERC20 for IERC20;

    // Holds USDC, USDT and wM
    address constant USER = 0x77BAB32F75996de8075eBA62aEa7b1205cf7E004;

    function setUp() public override {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_757_587);
        super.setUp();

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
                    blacklistManager,
                    yieldRecipientManager
                ),
                mExtensionDeployOptions
            )
        );

        _addToList(EARNERS_LIST, address(mYieldToOne));

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

    function test_initialState() external {
        assertEq(swapAdapter.uniswapRouter(), UNISWAP_V3_ROUTER);
        assertEq(swapAdapter.wrappedMToken(), WRAPPED_M);
        assertEq(swapAdapter.swapFacility(), address(swapFacility));
        assertTrue(swapAdapter.whitelistedToken(USDC));
        assertTrue(swapAdapter.whitelistedToken(USDT));
    }

    function test_swapIn_USDC_to_wrappedM() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(USER);
        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(USDC).approve(address(swapAdapter), amountIn);
        swapAdapter.swapIn(USDC, amountIn, WRAPPED_M, minAmountOut, USER, "");

        uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(USER);
        uint256 wrappedMBalanceAfter = IERC20(WRAPPED_M).balanceOf(USER);

        assertEq(usdcBalanceAfter, usdcBalanceBefore - amountIn);
        assertApproxEqAbs(wrappedMBalanceAfter, wrappedMBalanceBefore + amountIn, 1000);
    }

    function test_swapIn_USDC_to_mYieldToOne() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(USER);
        uint256 mYieldToOneBalanceBefore = mYieldToOne.balanceOf(USER);

        vm.startPrank(USER);
        IERC20(USDC).approve(address(swapAdapter), amountIn);
        swapAdapter.swapIn(USDC, amountIn, address(mYieldToOne), minAmountOut, USER, "");

        uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(USER);
        uint256 mYieldToOneBalanceAfter = mYieldToOne.balanceOf(USER);

        assertEq(usdcBalanceAfter, usdcBalanceBefore - amountIn);
        assertApproxEqAbs(mYieldToOneBalanceAfter, mYieldToOneBalanceBefore + amountIn, 1000);
    }

    function test_swapIn_USDC_to_mYieldToOne_blacklistedAccount() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(USER);

        vm.startPrank(USER);
        IERC20(USDC).approve(address(swapAdapter), amountIn);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, USER));
        swapAdapter.swapIn(USDC, amountIn, address(mYieldToOne), minAmountOut, USER, "");
    }

    function test_swapIn_USDT_to_WrappedM() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(USER);
        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        // Encode path for USDT -> USDC -> Wrapped M
        bytes memory path = abi.encodePacked(
            USDT,
            uint24(100), // 0.01% fee
            USDC,
            uint24(100), // 0.01% fee
            WRAPPED_M
        );

        vm.startPrank(USER);
        IERC20(USDT).forceApprove(address(swapAdapter), amountIn);
        swapAdapter.swapIn(USDT, amountIn, WRAPPED_M, minAmountOut, USER, path);

        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(USER);
        uint256 wrappedMBalanceAfter = IERC20(WRAPPED_M).balanceOf(USER);

        assertEq(usdtBalanceAfter, usdtBalanceBefore - amountIn);
        assertApproxEqAbs(wrappedMBalanceAfter, wrappedMBalanceBefore + amountIn, 1000);
    }

    function test_swapOut_wrappedM_to_USDC() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(USER);
        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(WRAPPED_M).approve(address(swapAdapter), amountIn);
        swapAdapter.swapOut(WRAPPED_M, amountIn, USDC, minAmountOut, USER, "");

        uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(USER);
        uint256 wrappedMBalanceAfter = IERC20(WRAPPED_M).balanceOf(USER);

        assertEq(wrappedMBalanceAfter, wrappedMBalanceBefore - amountIn);
        assertApproxEqAbs(usdcBalanceAfter, usdcBalanceBefore + amountIn, 1000);
    }

    function test_swapOut_wrappedM_to_USDT() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(USER);
        uint256 wrappedMBalanceBefore = IERC20(WRAPPED_M).balanceOf(USER);

        // Encode path for USDT -> USDC -> Wrapped M
        bytes memory path = abi.encodePacked(
            WRAPPED_M,
            uint24(100), // 0.01% fee
            USDC,
            uint24(100), // 0.01% fee
            USDT
        );

        vm.startPrank(USER);
        IERC20(WRAPPED_M).approve(address(swapAdapter), amountIn);
        swapAdapter.swapOut(WRAPPED_M, amountIn, USDT, minAmountOut, USER, path);

        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(USER);
        uint256 wrappedMBalanceAfter = IERC20(WRAPPED_M).balanceOf(USER);

        assertEq(wrappedMBalanceAfter, wrappedMBalanceBefore - amountIn);
        assertApproxEqAbs(usdtBalanceAfter, usdtBalanceBefore + amountIn, 1000);
    }

    function test_swapOutToken_mYieldToOne_to_USDC() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        uint256 usdcBalanceBefore = IERC20(USDC).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amountIn);
        swapFacility.swapInM(address(mYieldToOne), amountIn, USER);

        mYieldToOne.approve(address(swapAdapter), amountIn);
        swapAdapter.swapOut(address(mYieldToOne), amountIn, USDC, minAmountOut, USER, "");

        uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(USER);
        assertApproxEqAbs(usdcBalanceAfter, usdcBalanceBefore + amountIn, 1000);
    }

    function test_swapOutToken_mYieldToOne_to_USDT() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 997_000;
        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(USER);

        vm.startPrank(USER);
        IERC20(address(mToken)).approve(address(swapFacility), amountIn);
        swapFacility.swapInM(address(mYieldToOne), amountIn, USER);

        // Encode path for USDT -> USDC -> Wrapped M
        bytes memory path = abi.encodePacked(
            WRAPPED_M,
            uint24(100), // 0.01% fee
            USDC,
            uint24(100), // 0.01% fee
            USDT
        );

        mYieldToOne.approve(address(swapAdapter), amountIn);
        swapAdapter.swapOut(address(mYieldToOne), amountIn, USDT, minAmountOut, USER, path);

        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(USER);
        assertApproxEqAbs(usdtBalanceAfter, usdtBalanceBefore + amountIn, 1000);
    }
}
