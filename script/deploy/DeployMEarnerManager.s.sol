// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ScriptBase } from "./ScriptBase.s.sol";  

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MEarnerManager } from "../../src/projects/earnerManager/MEarnerManager.sol";

contract DeployMEarnerManager is ScriptBase {

  MEarnerManager public earnerManager;

  function run () public {

    vm.startBroadcast();

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    Options memory opts;

    opts.constructorData = abi.encode(
      _getMToken(),
      _getSwapFacility()
    );

    earnerManager = MEarnerManager(
      Upgrades.deployTransparentProxy(
        "MEarnerManager.sol:MEarnerManager",
        deployer,
        abi.encodeWithSelector(
          MEarnerManager.initialize.selector,
          _getName(),
          _getSymbol(),
          _getAdmin(),
          _getEarnerManager(),
          _getFeeRecipient()
        ),
        opts
      )
    );

    vm.stopBroadcast();

  }

}