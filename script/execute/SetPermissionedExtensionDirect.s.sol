// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { ScriptBase } from "../ScriptBase.s.sol";
import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

/**
 * @title  SetPermissionedExtensionDirect
 * @notice EOA-broadcast script that calls SwapFacility.setPermissionedExtension(extension, true)
 *         directly via the deployer key. Used by m0-launchpad ONLY on testnet networks where
 *         the deployer EOA holds DEFAULT_ADMIN_ROLE on the SwapFacility contract.
 *
 *         On mainnet, DEFAULT_ADMIN_ROLE is held by a multisig and the launchpad routes the
 *         same logical action through the Phase 11 multisig-propose path
 *         (ProposeSetPermissionedExtension). This script MUST NOT be invoked on mainnet — the
 *         launchpad's resolveDispatchTarget is the primary safety gate; contract-level
 *         onlyRole(DEFAULT_ADMIN_ROLE) is the implicit second gate per Phase 10.1 CONTEXT.md D-04.
 *
 * @dev Required env vars: PRIVATE_KEY, EXTENSION_ADDRESS, SWAP_FACILITY_ADDRESS
 *      Usage: make set-permissioned-extension-testnet-direct \
 *               RPC_URL=<rpc> SWAP_FACILITY_ADDRESS=<addr> EXTENSION_ADDRESS=<addr>
 */
contract SetPermissionedExtensionDirect is ScriptBase {
    function run() external {
        address swapFacility_ = vm.envAddress("SWAP_FACILITY_ADDRESS");
        address extension_ = vm.envAddress("EXTENSION_ADDRESS");

        console.log("Chain ID:", block.chainid);
        console.log("SwapFacility:", swapFacility_);
        console.log("Extension:", extension_);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ISwapFacility(swapFacility_).setPermissionedExtension(extension_, true);

        vm.stopBroadcast();

        console.log("setPermissionedExtension(extension, true) broadcast on SwapFacility:", swapFacility_);
    }
}
