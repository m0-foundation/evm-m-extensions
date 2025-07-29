// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeploySwapFacilityBase } from "./DeploySwapFacilityBase.s.sol";  
import { console } from "forge-std/console.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

contract DeploySwapFacility is DeploySwapFacilityBase {

  function run () public {

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    vm.startBroadcast();

    address swapFacility_ = _deploySwapFacility(block.chainid, deployer);

    vm.stopBroadcast();

    console.log("SwapFacility:", swapFacility_);

    _writeDeployment(block.chainid, "swapFacility", swapFacility_);

  }

}