// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UpgradeBase } from "./UpgradeBase.sol";

contract UpgradeJMIExtension is UpgradeBase {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address jmiExtension = vm.envAddress("EXTENSION_ADDRESS");

        vm.startBroadcast(deployer);

        _upgradeJMIExtension(jmiExtension);

        vm.stopBroadcast();
    }
}
