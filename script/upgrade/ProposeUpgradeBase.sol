// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { IProxyAdmin } from "../../lib/openzeppelin-foundry-upgrades/src/internal/interfaces/IProxyAdmin.sol";
import { MultiSigBatchBase } from "../../lib/common/script/MultiSigBatchBase.sol";
import { Options } from "../../lib/openzeppelin-foundry-upgrades/src/Options.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

import { Config } from "../Config.sol";

/**
 * @title  ProposeUpgradeBase
 * @notice Base contract for multisig upgrade proposal scripts.
 * @dev    NOTE: This contract duplicates `Deployments` struct and `_readDeployment` from ScriptBase
 *         instead of inheriting it. This is intentional to avoid diamond inheritance issues
 *         in the IDE (both MultiSigBatchBase and ScriptBase extend Script).
 */
contract ProposeUpgradeBase is MultiSigBatchBase, Config {
    /// @dev Duplicated from ScriptBase to avoid diamond inheritance with MultiSigBatchBase
    struct Deployments {
        address[] extensionAddresses;
        string[] extensionNames;
        address swapAdapter;
        address swapFacility;
    }

    function _proposeSwapFacilityUpgrade(
        address proposer,
        address safeMultisig,
        address swapFacility,
        address pauser
    ) internal {
        string memory contractPath = "SwapFacility.sol:SwapFacility";
        DeployConfig memory config = _getDeployConfig(block.chainid);

        address proxyAdmin = Upgrades.getAdminAddress(swapFacility);

        console.log("================================================================================");
        console.log("ProposeSwapFacilityUpgrade");
        console.log("================================================================================");
        console.log("Chain ID:            ", block.chainid);
        console.log("Proposer:            ", proposer);
        console.log("Safe Multisig:       ", safeMultisig);
        console.log("SwapFacility Proxy:  ", swapFacility);
        console.log("ProxyAdmin:          ", proxyAdmin);
        console.log("M Token:             ", config.mToken);
        console.log("Registrar:           ", config.registrar);
        console.log("Pauser:              ", pauser);
        console.log("================================================================================");

        // Step 1: Validate upgrade safety and deploy new implementation using Upgrades.prepareUpgrade
        // Note: unsafeSkipStorageCheck=true skips storage layout comparison (no previous version available)
        // but still validates upgrade safety rules (no constructor logic, proper initializers, etc.)
        Options memory opts;
        opts.constructorData = abi.encode(config.mToken, config.registrar);
        opts.unsafeSkipStorageCheck = true;

        console.log("Validating and deploying new implementation...");
        vm.startBroadcast(proposer);
        address newImplementation = Upgrades.prepareUpgrade(contractPath, opts);
        vm.stopBroadcast();

        console.log("New Implementation:  ", newImplementation);

        // Step 2: Prepare the upgradeAndCall data
        bytes memory initializeV2Data = abi.encodeWithSelector(SwapFacility.initializeV2.selector, pauser);

        // Step 3: Add upgradeAndCall to batch
        _addToBatch(
            proxyAdmin,
            abi.encodeCall(IProxyAdmin.upgradeAndCall, (swapFacility, newImplementation, initializeV2Data))
        );

        // Step 4: Simulate and propose the batch
        console.log("--------------------------------------------------------------------------------");
        console.log("Simulating batch...");
        _simulateBatch(safeMultisig);
        console.log("Simulation successful!");

        console.log("--------------------------------------------------------------------------------");
        console.log("Proposing batch to Safe...");
        vm.startBroadcast(proposer);
        _proposeBatch(safeMultisig, proposer);
        vm.stopBroadcast();

        console.log("================================================================================");
        console.log("SwapFacility upgrade proposed successfully!");
        console.log("================================================================================");
    }

    /// @dev Duplicated from ScriptBase to avoid diamond inheritance with MultiSigBatchBase
    function _deployOutputPath(uint256 chainId_) internal view returns (string memory) {
        return string.concat(vm.projectRoot(), "/deployments/", vm.toString(chainId_), ".json");
    }

    /// @dev Duplicated from ScriptBase to avoid diamond inheritance with MultiSigBatchBase
    function _readDeployment(uint256 chainId_) internal returns (Deployments memory) {
        if (!vm.isFile(_deployOutputPath(chainId_))) {
            return Deployments(new address[](0), new string[](0), address(0), address(0));
        }

        bytes memory data = vm.parseJson(vm.readFile(_deployOutputPath(chainId_)));

        return abi.decode(data, (Deployments));
    }
}
