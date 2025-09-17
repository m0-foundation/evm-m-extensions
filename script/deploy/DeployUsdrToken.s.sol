// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { UsdrToken } from "../../src/UsdrToken.sol";
import { console } from "forge-std/console.sol";

contract DeployUsdrToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploying a Transparent Proxy, which requires a proxy admin.
        address proxy = Upgrades.deployTransparentProxy(
            "UsdrToken.sol",          // Contract file name
            deployer,                       // The admin for the proxy contract itself
            abi.encodeCall(                 // The initializer call data
                UsdrToken.initialize,
                (
                    "USDR testnet",        // name
                    "USDR",                   // symbol
                    deployer,                    // yieldRecipient
                    deployer,                    // admin (DEFAULT_ADMIN_ROLE for the logic)
                    deployer,                    // freezeManager
                    deployer                     // yieldRecipientManager
                )
            )
        );

        vm.stopBroadcast();

        console.log("UsdrToken deployed at:", proxy);
    }
}