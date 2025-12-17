// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeployMEarnerManager is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        MEarnerManagerConfig memory extensionConfig;

        extensionConfig.name = vm.envString("EXTENSION_NAME");
        extensionConfig.symbol = vm.envString("EXTENSION_SYMBOL");
        extensionConfig.admin = vm.envAddress("ADMIN");
        extensionConfig.earnerManager = vm.envAddress("EARNER_MANAGER");
        extensionConfig.feeRecipient = vm.envAddress("FEE_RECIPIENT");
        extensionConfig.pauser = vm.envAddress("PAUSER");

        // Verify predicted address (if PREDICTED_ADDRESS env var is set)
        if (_shouldVerifyPredictedAddress()) {
            _verifyPredictedAddress(deployer, "MEarnerManager");
        }

        vm.startBroadcast(deployer);

        (
            address earnerManagerImplementation,
            address earnerManagerProxy,
            address earnerManagerProxyAdmin
        ) = _deployMEarnerManager(deployer, extensionConfig);

        vm.stopBroadcast();

        console.log("EarnerManagerImplementation:", earnerManagerImplementation);
        console.log("EarnerManagerProxy:", earnerManagerProxy);
        console.log("EarnerManagerProxyAdmin:", earnerManagerProxyAdmin);

        _writeDeployment(block.chainid, _getExtensionName(), earnerManagerProxy);
    }
}
