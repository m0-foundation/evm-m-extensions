// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { IERC20 } from ".../../lib/common/src/interfaces/IERC20.sol";
import { SafeERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { SwapFacility } from "../../src/SwapFacility.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract SwapFacilityIntegrationTest is BaseIntegrationTest {
    using SafeERC20 for IERC20;

    // Holds USDC, USDT and wM
    address constant USER = 0x77BAB32F75996de8075eBA62aEa7b1205cf7E004;

    function setUp() public override {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_751_329);

        super.setUp();
    }

    function test_swapTokenIn_USDC_to_WrappedM() public {
        uint256 amountIn = 1_000_000;
        uint256 minAmountOut = 0;

        vm.prank(USER);
        IERC20(USDC).approve(address(swapFacility), amountIn);

        //vm.prank(USER);
        //swapFacility.swapTokenIn(USDC, amountIn, WRAPPED_M, minAmountOut, USER, "");
    }
}
