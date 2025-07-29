// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ScriptBase } from "./ScriptBase.s.sol";  

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

contract DeploySwapFacility is ScriptBase {

  SwapFacility public swapFacility;

  function run () public {

    vm.startBroadcast();

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    Options memory opts;

    opts.constructorData = abi.encode(
      _getMToken(),
      _getRegistrar()
    );

    swapFacility = SwapFacility(
      Upgrades.deployTransparentProxy(
        "SwapFacility.sol:SwapFacility",
        deployer,
        abi.encodeWithSelector(SwapFacility.initialize.selector, deployer),
        opts
      )
    );

    vm.stopBroadcast();

  }

}