// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";
import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";
import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";
import { IMExtension } from "../../src/interfaces/IMExtension.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MainnetDeploymentSim is DeployBase {
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        address pauser = vm.envAddress("PAUSER");

        vm.startPrank(deployer);

        (, address swapFacilityProxy, ) = _deploySwapFacility(deployer, pauser);

        console.log("SwapFacilityProxy:", swapFacilityProxy);

        vm.setEnv("SWAP_FACILITY", vm.toString(swapFacilityProxy));

        address swapAdapter = _deploySwapAdapter(deployer);

        console.log("SwapAdapter:", swapAdapter);

        SwapFacility facility = SwapFacility(swapFacilityProxy);
        UniswapV3SwapAdapter adapter = UniswapV3SwapAdapter(swapAdapter);

        facility.grantRole(facility.M_SWAPPER_ROLE(), deployer);

        IMTokenLike m = IMTokenLike(M_TOKEN);
        IMExtension wm = IMExtension(WRAPPED_M_TOKEN);

        console.log("m", address(m));

        m.approve(address(facility), type(uint256).max);
        wm.approve(address(facility), type(uint256).max);
        wm.approve(address(adapter), type(uint256).max);
        IERC20(USDC).approve(address(adapter), type(uint256).max);

        facility.swap(M_TOKEN, WRAPPED_M_TOKEN, 10000, deployer);

        uint256 wmBalance = wm.balanceOf(deployer);

        console.log("wmBalance", wmBalance);

        adapter.swapOut(WRAPPED_M_TOKEN, wmBalance, USDC, 0, deployer, "");

        uint256 usdcBalance = IERC20(USDC).balanceOf(deployer);

        console.log("usdcBalance", usdcBalance);

        adapter.swapIn(USDC, usdcBalance, WRAPPED_M_TOKEN, 0, deployer, "");

        wmBalance = wm.balanceOf(deployer);

        console.log("wmBalance", wmBalance);

        uint256 mBalanceBefore = m.balanceOf(deployer);

        facility.swap(WRAPPED_M_TOKEN, M_TOKEN, wmBalance, deployer);

        uint256 mBalanceAfter = m.balanceOf(deployer);

        console.log("mBalance", mBalanceAfter - mBalanceBefore);

        vm.stopPrank();
    }
}
