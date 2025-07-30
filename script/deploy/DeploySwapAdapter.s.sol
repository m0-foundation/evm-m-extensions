// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";  
import { console } from "forge-std/console.sol";

contract DeploySwapAdapter is DeployBase {

  function run () public {

    address deployer_ = vm.addr(vm.envUint("PRIVATE_KEY"));

    vm.startBroadcast();

    ( address swapAdaterImplementation, 
      address swapAdapterProxy, 
      address swapAdapterProxyAdmin 
    ) = _deploySwapAdapter(deployer_, deployer_);

    vm.stopBroadcast();

    console.log("SwapAdapterImplementation:", swapAdaterImplementation);
    console.log("SwapAdapterProxy:", swapAdapterProxy);
    console.log("SwapAdapterProxyAdmin:", swapAdapterProxyAdmin);

    _writeDeployment(block.chainid, "swapAdapter", swapAdapterProxy);

  }

}