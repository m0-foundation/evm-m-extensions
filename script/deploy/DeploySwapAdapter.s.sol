// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeploySwapAdapter is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        address swapAdater = _deploySwapAdapter(deployer);

        vm.stopBroadcast();

        console.log("SwapAdapter:", swapAdater);

        _writeDeployment(block.chainid, "swapAdapter", swapAdater);
    }
}
