// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";  

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MYieldFee } from "../../src/projects/yieldToAllWithFee/MYieldFee.sol";

contract DeployYeildToAllWithFee is DeployBase {

  MYieldFee public yieldToAllWithFee;

  function run () public {

    vm.startBroadcast();

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    Options memory opts;

    opts.constructorData = abi.encode(
      _getMToken(),
      _getSwapFacility()
    );

    yieldToAllWithFee = MYieldFee(
      Upgrades.deployTransparentProxy(
        "MYieldFee.sol:MYieldFee",
        deployer,
        abi.encodeWithSelector(
          MYieldFee.initialize.selector, 
          _getName(),
          _getSymbol(),
          _getFeeRate(),
          _getFeeRecipient(),
          _getAdmin(),
          _getFeeManager(),
          _getClaimRecipientManager()
        ),
        opts
      )
    );

    vm.stopBroadcast();

  }

}