// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import { UpgradeSwapFacilityBase } from "./UpgradeSwapFacilityBase.sol";

contract UpgradeSwapFacility is UpgradeSwapFacilityBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        Deployments memory deployments_ = _readDeployment(block.chainid);

        vm.startBroadcast(deployer_);

        _upgradeSwapFacility(deployments_.swapFacility);

        vm.stopBroadcast();
    }
}
