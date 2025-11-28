// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeployJMIExtension is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        (
            address jmiExtensionImplementation,
            address jmiExtensionProxy,
            address jmiExtensionProxyAdmin
        ) = _deployJMIExtension(deployer);

        vm.stopBroadcast();

        console.log("JMIExtensionImplementation:", jmiExtensionImplementation);
        console.log("JMIExtensionProxy:", jmiExtensionProxy);
        console.log("JMIExtensionProxyAdmin:", jmiExtensionProxyAdmin);

        _writeDeployment(block.chainid, _getExtensionName(), jmiExtensionProxy);
    }
}
