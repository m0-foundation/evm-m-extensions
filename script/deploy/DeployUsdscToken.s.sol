// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import { UsdscToken } from "../../src/UsdscToken.sol";
import { console } from "../../lib/forge-std/src/console.sol";

contract DeployUsdscToken is DeployBase {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        (address usdscImplementation, address usdscProxy, address usdscProxyAdmin) = _deployUsdsc(deployer);

        vm.stopBroadcast();

        console.log("UsdscToken deployed at:", usdscProxy);
        console.log("UsdscImplementation:", usdscImplementation);
        console.log("UsdscProxy:", usdscProxy);
        console.log("UsdscProxyAdmin:", usdscProxyAdmin);
        _writeDeployment(block.chainid, _getExtensionName(), usdscProxy);
    }
}
