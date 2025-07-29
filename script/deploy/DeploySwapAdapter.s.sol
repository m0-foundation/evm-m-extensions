// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ScriptBase } from "./ScriptBase.s.sol";  

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";

contract DeploySwapAdapter is ScriptBase {

  UniswapV3SwapAdapter public swapAdapter;

  function run () public {

    vm.startBroadcast();

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    Options memory opts;

    opts.constructorData = abi.encode(
      _getMToken(),
      _getSwapFacility(),
      _getUniswapRouter(),
      _getAdmin(),
      _getWhitelistedTokens()
    );

    swapAdapter = UniswapV3SwapAdapter(
      Upgrades.deployTransparentProxy(
        "UniswapV3SwapAdapter.sol:UniswapV3SwapAdapter",
        deployer,
        ""
      )
    );

    vm.stopBroadcast();

  }

}