// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { JMIExtension } from "../../src/projects/jmi/JMIExtension.sol";
import { UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract UpgradeJMIExtensionWithRescue is Script {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address jmiExtension = vm.envAddress("EXTENSION_ADDRESS");
        address rescueToken = vm.envAddress("RESCUE_TOKEN");
        address rescueRecipient = vm.envAddress("RESCUE_RECIPIENT");

        console.log("Deployer:", deployer);
        console.log("JMI Extension Proxy:", jmiExtension);
        console.log("Rescue Token:", rescueToken);
        console.log("Rescue Recipient:", rescueRecipient);

        // Read immutables from existing proxy
        address mToken = JMIExtension(jmiExtension).mToken();
        address swapFacility = JMIExtension(jmiExtension).swapFacility();

        console.log("M Token (from proxy):", mToken);
        console.log("Swap Facility (from proxy):", swapFacility);

        vm.startBroadcast(deployer);

        // Deploy new implementation
        JMIExtension implementation = new JMIExtension(mToken, swapFacility);
        console.log("New Implementation:", address(implementation));

        // Upgrade proxy and call initializeV2
        UnsafeUpgrades.upgradeProxy(
            jmiExtension,
            address(implementation),
            abi.encodeWithSelector(JMIExtension.initializeV2.selector, rescueToken, rescueRecipient)
        );

        console.log("Upgrade completed successfully!");

        vm.stopBroadcast();
    }
}
