// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UpgradeJMIExtensionBase } from "./UpgradeJMIExtensionBase.sol";

contract UpgradeJMIExtension is UpgradeJMIExtensionBase {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        Deployments memory deployments = _readDeployment(block.chainid);
        string memory extensionName = _getExtensionName();

        address jmiExtension;
        for (uint256 i = 0; i < deployments.extensionNames.length; i++) {
            if (keccak256(bytes(deployments.extensionNames[i])) == keccak256(bytes(extensionName))) {
                jmiExtension = deployments.extensionAddresses[i];
                break;
            }
        }

        require(jmiExtension != address(0), "JMI Extension not found in deployments");

        vm.startBroadcast(deployer);

        _upgradeJMIExtension(jmiExtension);

        vm.stopBroadcast();
    }
}
