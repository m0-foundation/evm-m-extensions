// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UpgradeSwapAdapterBase } from "./UpgradeSwapAdapterBase.sol";

contract UpgradeSwapAdapter is UpgradeSwapAdapterBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        Deployments memory deployments_ = _readDeployment(block.chainid);

        vm.startBroadcast(deployer_);

        _upgradeSwapAdapter(deployments_.swapFacility);

        vm.stopBroadcast();
    }
}
