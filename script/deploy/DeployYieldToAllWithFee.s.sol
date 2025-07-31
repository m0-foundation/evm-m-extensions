// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeployYeildToAllWithFee is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();

        (
            address yieldToAllWithFeeImplementation,
            address yieldToAllWithFeeProxy,
            address yieldToAllWithFeeProxyAdmin
        ) = _deployYieldToAllWithFee(deployer, deployer);

        vm.stopBroadcast();

        console.log("YieldToAllWithFeeImplementation:", yieldToAllWithFeeImplementation);
        console.log("YieldToAllWithFeeProxy:", yieldToAllWithFeeProxy);
        console.log("YieldToAllWithFeeProxyAdmin:", yieldToAllWithFeeProxyAdmin);

        _writeDeployment(block.chainid, _getExtensionName(), yieldToAllWithFeeProxy);
    }
}
