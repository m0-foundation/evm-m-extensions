// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeployJMIExtension is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        JMIExtensionConfig memory extensionConfig;

        extensionConfig.name = vm.envString("EXTENSION_NAME");
        extensionConfig.symbol = vm.envString("EXTENSION_SYMBOL");
        extensionConfig.yieldRecipient = vm.envAddress("YIELD_RECIPIENT");
        extensionConfig.admin = vm.envAddress("ADMIN");
        extensionConfig.assetCapManager = vm.envAddress("ASSET_CAP_MANAGER");
        extensionConfig.freezeManager = vm.envAddress("FREEZE_MANAGER");
        extensionConfig.pauser = vm.envAddress("PAUSER");
        extensionConfig.yieldRecipientManager = vm.envAddress("YIELD_RECIPIENT_MANAGER");

        // Check for predicted address (optional)
        address predictedAddress = vm.envOr("PREDICTED_ADDRESS", address(0));

        // If predicted address is set, simulate first to verify
        if (predictedAddress != address(0)) {
            console.log("PREDICTED_ADDRESS is set, running simulation to verify...");

            // Simulate deployment to get the actual address
            (, address simulatedProxy, ) = _deployJMIExtension(deployer, extensionConfig);

            console.log("Predicted address:", predictedAddress);
            console.log("Simulated address:", simulatedProxy);

            // Compare addresses
            require(
                simulatedProxy == predictedAddress,
                string.concat(
                    "Address mismatch! Predicted: ",
                    vm.toString(predictedAddress),
                    ", but simulation resulted in: ",
                    vm.toString(simulatedProxy)
                )
            );

            console.log("Address verification passed! Proceeding with deployment...");
        }

        vm.startBroadcast(deployer);

        (
            address jmiExtensionImplementation,
            address jmiExtensionProxy,
            address jmiExtensionProxyAdmin
        ) = _deployJMIExtension(deployer, extensionConfig);

        vm.stopBroadcast();

        console.log("JMIExtensionImplementation:", jmiExtensionImplementation);
        console.log("JMIExtensionProxy:", jmiExtensionProxy);
        console.log("JMIExtensionProxyAdmin:", jmiExtensionProxyAdmin);

        _writeDeployment(block.chainid, _getExtensionName(), jmiExtensionProxy);
    }
}
