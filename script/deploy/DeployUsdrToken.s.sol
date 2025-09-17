// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { UsdrToken } from "../../src/UsdrToken.sol";
import { console } from "forge-std/console.sol";

contract DeployUsdrToken is DeployBase {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        (address usdrImplementation, address usdrProxy, address usdrProxyAdmin) = _deployUsdr(
            deployer
        );

        vm.stopBroadcast();

        console.log("UsdrToken deployed at:", usdrProxy);

        console.log("UsdrImplementation:", usdrImplementation);
        console.log("UsdrProxy:", usdrProxy);
        console.log("UsdrProxyAdmin:", usdrProxyAdmin);
        _writeDeployment(block.chainid, _getExtensionName(), usdrProxy);
    }
}