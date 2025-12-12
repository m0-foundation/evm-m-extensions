// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UpgradeBase } from "./UpgradeBase.sol";

contract UpgradeOldSwapFacility is UpgradeBase {
    function run() external {

        if (block.chainid != SEPOLIA_CHAIN_ID) {
            revert("This upgrade script is only for Sepolia");
        }

        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address oldSwapFacility = 0xde4Dd70f09F3c76455D3E5D5D87eF0c9E59Aa1Ff;

        vm.startBroadcast(deployer);

        _upgradeOldSwapFacility(oldSwapFacility);
        vm.stopBroadcast();
    }
}
