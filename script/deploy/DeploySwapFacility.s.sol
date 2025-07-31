// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeploySwapFacility is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();

        (
            address swapFacilityImplementation,
            address swapFacilityProxy,
            address swapFacilityProxyAdmin
        ) = _deploySwapFacility(deployer);

        vm.stopBroadcast();

        console.log("SwapFacilityImplementation:", swapFacilityImplementation);
        console.log("SwapFacilityProxy:", swapFacilityProxy);
        console.log("SwapFacilityProxyAdmin:", swapFacilityProxyAdmin);

        _writeDeployment(block.chainid, "swapFacility", swapFacilityProxy);
    }
}
