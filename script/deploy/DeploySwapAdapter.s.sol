// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeploySwapAdapterBase } from "./DeploySwapAdapterBase.s.sol";  
import { console } from "forge-std/console.sol";

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";

contract DeploySwapAdapter is DeploySwapAdapterBase {

  function run () public {

    address deployer_ = vm.addr(vm.envUint("PRIVATE_KEY"));

    vm.startBroadcast();

    address swapAdater_ = _deploySwapAdapter(block.chainid, deployer_);

    vm.stopBroadcast();

    console.log("SwapAdapter:", swapAdater_);

    _writeDeployment(block.chainid, "swapAdapter", swapAdater_);

  }

}