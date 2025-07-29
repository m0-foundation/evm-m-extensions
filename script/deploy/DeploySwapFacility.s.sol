// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeploySwapFacilityBase } from "./DeploySwapFacilityBase.s.sol";  
import { console } from "forge-std/console.sol";

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

contract DeploySwapFacility is DeploySwapFacilityBase {

  SwapFacility public swapFacility;

  function run () public {

    address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

    vm.startBroadcast();

    address swapFacility_ = _deploySwapFacility(block.chainid, deployer);

    vm.stopBroadcast();

    console.log("SwapFacility:", swapFacility_);

    _writeDeployment(block.chainid, "swapFacility", swapFacility_);

  }

}