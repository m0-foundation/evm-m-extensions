// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeployYieldToAllWithFee is DeployBase {
    function run() public {
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        YieldToAllWithFeeConfig memory extensionConfig;

        extensionConfig.name = vm.envString("EXTENSION_NAME");
        extensionConfig.symbol = vm.envString("EXTENSION_SYMBOL");
        extensionConfig.feeRate = uint16(vm.envUint("FEE_RATE"));
        extensionConfig.feeRecipient = vm.envAddress("FEE_RECIPIENT");
        extensionConfig.admin = vm.envAddress("ADMIN");
        extensionConfig.feeManager = vm.envAddress("FEE_MANAGER");
        extensionConfig.claimRecipientManager = vm.envAddress("CLAIM_RECIPIENT_MANAGER");
        extensionConfig.freezeManager = vm.envAddress("FREEZE_MANAGER");
        extensionConfig.pauser = vm.envAddress("PAUSER");

        // Simulate deployment to verify predicted address (if PREDICTED_ADDRESS env var is set)
        if (_shouldVerifyPredictedAddress()) {
            (, address simulatedProxy, ) = _deployYieldToAllWithFee(deployer, extensionConfig);
            _verifyPredictedAddress(simulatedProxy, "MYieldFee");
        }

        vm.startBroadcast(deployer);

        (
            address yieldToAllWithFeeImplementation,
            address yieldToAllWithFeeProxy,
            address yieldToAllWithFeeProxyAdmin
        ) = _deployYieldToAllWithFee(deployer, extensionConfig);

        vm.stopBroadcast();

        console.log("YieldToAllWithFeeImplementation:", yieldToAllWithFeeImplementation);
        console.log("YieldToAllWithFeeProxy:", yieldToAllWithFeeProxy);
        console.log("YieldToAllWithFeeProxyAdmin:", yieldToAllWithFeeProxyAdmin);

        _writeDeployment(block.chainid, _getExtensionName(), yieldToAllWithFeeProxy);
    }
}
