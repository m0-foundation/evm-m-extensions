// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeployMEarnerManager is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        (
            address earnerManagerImplementation,
            address earnerManagerProxy,
            address earnerManagerProxyAdmin
        ) = _deployMEarnerManager(deployer);

        vm.stopBroadcast();

        console.log("EarnerManagerImplementation:", earnerManagerImplementation);
        console.log("EarnerManagerProxy:", earnerManagerProxy);
        console.log("EarnerManagerProxyAdmin:", earnerManagerProxyAdmin);

        _writeDeployment(block.chainid, _getExtensionName(), earnerManagerProxy);
    }
}
