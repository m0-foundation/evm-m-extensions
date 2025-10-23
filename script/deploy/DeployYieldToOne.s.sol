// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeployYieldToOne is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        (address yieldToOneImplementation, address yieldToOneProxy, address yieldToOneProxyAdmin) = _deployYieldToOne(
            deployer
        );

        vm.stopBroadcast();

        console.log("YieldToOneImplementation:", yieldToOneImplementation);
        console.log("YieldToOneProxy:", yieldToOneProxy);
        console.log("YieldToOneProxyAdmin:", yieldToOneProxyAdmin);

        _writeDeployment(block.chainid, _getExtensionName(), yieldToOneProxy);
    }
}
