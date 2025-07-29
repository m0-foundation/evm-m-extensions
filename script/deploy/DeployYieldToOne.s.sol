// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MYieldToOne } from "../../src/projects/yieldToOne/MYieldToOne.sol";

import { ScriptBase } from "./ScriptBase.s.sol";  

contract DeployYieldToOne is ScriptBase {

  MYieldToOne public yieldToOne;

  function run () public {

    vm.startBroadcast();

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    Options memory opts;

    opts.constructorData = abi.encode(
      _getMToken(),
      _getSwapFacility()
    );

    yieldToOne = MYieldToOne(
      Upgrades.deployTransparentProxy(
        "MYieldToOne.sol:MYieldToOne",
        deployer,
        abi.encodeWithSelector(
          MYieldToOne.initialize.selector, 
          _getName(), 
          _getSymbol(), 
          _getYieldRecipient(),
          _getAdmin(),
          _getBlacklistManager(), 
          _getYieldRecipientManager()
        ),
        opts
      )
    );

    vm.stopBroadcast();

  }

}