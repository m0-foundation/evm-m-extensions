// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import { UpgradeBase } from "./UpgradeBase.sol";

contract UpgradeSwapFacility is UpgradeBase {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address pauser = vm.envAddress("PAUSER");

        Deployments memory deployments = _readDeployment(block.chainid);

        vm.startBroadcast(deployer);

        _upgradeSwapFacility(deployments.swapFacility, pauser);

        vm.stopBroadcast();
    }
}
