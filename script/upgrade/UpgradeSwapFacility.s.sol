// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UpgradeSwapFacilityBase } from "./UpgradeSwapFacilityBase.sol";

contract UpgradeSwapFacility is UpgradeSwapFacilityBase {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address pauser = vm.envAddress("PAUSER");

        Deployments memory deployments = _readDeployment(block.chainid);

        vm.startBroadcast(deployer);

        _upgradeSwapFacility(deployments.swapFacility, pauser);

        vm.stopBroadcast();
    }
}
