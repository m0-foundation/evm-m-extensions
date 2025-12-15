// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { UpgradeBase } from "./UpgradeBase.sol";

contract UpgradeOldSwapFacility is UpgradeBase {
    function run() external {
        if (block.chainid != SEPOLIA_CHAIN_ID) {
            revert("This upgrade script is only for Sepolia");
        }

        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        // Old SF, M(MONEY) and Registrar addresses used in earlier contract deployment
        address oldSwapFacility = 0xde4Dd70f09F3c76455D3E5D5D87eF0c9E59Aa1Ff;
        address oldMToken = 0x0c941AD94Ca4A52EDAeAbF203b61bdd1807CeEC0;
        address oldRegistrar = 0x975Bf5f212367D09CB7f69D3dc4BA8C9B440aD3A;

        vm.startBroadcast(deployer);

        _upgradeOldSwapFacility(oldSwapFacility, oldMToken, oldRegistrar);
        vm.stopBroadcast();
    }
}
