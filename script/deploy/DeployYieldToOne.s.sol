// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";  
import { console } from "forge-std/console.sol";

contract DeployYieldToOne is DeployBase {

  MYieldToOne public yieldToOne;

  function run () public {

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    vm.startBroadcast();

    ( address yieldToOneImplementation, 
      address yieldToOneProxy, 
      address yieldToOneProxyAdmin 
    ) = _deployYieldToOne(deployer, deployer);

    vm.stopBroadcast();

    console.log("YieldToOneImplementation:", yieldToOneImplementation);
    console.log("YieldToOneProxy:", yieldToOneProxy);
    console.log("YieldToOneProxyAdmin:", yieldToOneProxyAdmin);

  }

}