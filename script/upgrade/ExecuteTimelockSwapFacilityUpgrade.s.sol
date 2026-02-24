// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IProxyAdmin } from "../../lib/openzeppelin-foundry-upgrades/src/internal/interfaces/IProxyAdmin.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

import { ProposeTimelockUpgradeBase } from "./ProposeTimelockUpgradeBase.sol";

/// @title  ExecuteTimelockSwapFacilityUpgrade
/// @notice Executes a previously scheduled timelocked SwapFacility upgrade after the delay has elapsed.
contract ExecuteTimelockSwapFacilityUpgrade is ProposeTimelockUpgradeBase {
    function run() external {
        address sender = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address timelock = vm.envAddress("TIMELOCK_ADDRESS");
        address pauser = vm.envAddress("PAUSER");
        address newImplementation = vm.envAddress("NEW_IMPLEMENTATION");

        Deployments memory deployments = _readDeployment(block.chainid);

        require(deployments.swapFacility != address(0), "SwapFacility not deployed on this chain");

        address proxyAdmin = Upgrades.getAdminAddress(deployments.swapFacility);

        // Rebuild the same batch that was scheduled during proposal
        bytes memory initializeV2Data = abi.encodeWithSelector(SwapFacility.initializeV2.selector, pauser);

        bytes memory upgradeAndCallData = abi.encodeCall(
            IProxyAdmin.upgradeAndCall,
            (deployments.swapFacility, newImplementation, initializeV2Data)
        );

        _addToTimelockBatch(proxyAdmin, upgradeAndCallData);

        vm.startBroadcast(sender);
        _executeTimelockBatch(timelock, bytes32(0));
        vm.stopBroadcast();
    }
}
