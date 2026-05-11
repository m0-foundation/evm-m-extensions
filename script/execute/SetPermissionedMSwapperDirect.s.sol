// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { ScriptBase } from "../ScriptBase.s.sol";
import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

/**
 * @title  SetPermissionedMSwapperDirect
 * @notice EOA-broadcast script that calls SwapFacility.setPermissionedMSwapper(extension, swapper, true)
 *         directly via the deployer key. Used by m0-launchpad ONLY on testnet networks where
 *         the deployer EOA holds DEFAULT_ADMIN_ROLE on the SwapFacility contract.
 *
 *         Same mainnet caveat as SetPermissionedExtensionDirect — Phase 11's
 *         ProposeSetPermissionedMSwapper handles the mainnet multisig path. This script MUST
 *         NOT be invoked on mainnet (launchpad routing + contract-level access control are
 *         the two gates per Phase 10.1 CONTEXT.md D-04).
 *
 * @dev Required env vars: PRIVATE_KEY, EXTENSION_ADDRESS, SWAP_FACILITY_ADDRESS, SWAPPER_ADDRESS
 *      Usage: make set-permissioned-mswapper-testnet-direct \
 *               RPC_URL=<rpc> SWAP_FACILITY_ADDRESS=<addr> EXTENSION_ADDRESS=<addr> SWAPPER_ADDRESS=<addr>
 */
contract SetPermissionedMSwapperDirect is ScriptBase {
    function run() external {
        address swapFacility_ = vm.envAddress("SWAP_FACILITY_ADDRESS");
        address extension_ = vm.envAddress("EXTENSION_ADDRESS");
        address swapper_ = vm.envAddress("SWAPPER_ADDRESS");

        console.log("Chain ID:", block.chainid);
        console.log("SwapFacility:", swapFacility_);
        console.log("Extension:", extension_);
        console.log("Swapper:", swapper_);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        ISwapFacility(swapFacility_).setPermissionedMSwapper(extension_, swapper_, true);

        vm.stopBroadcast();

        console.log("setPermissionedMSwapper(extension, swapper, true) broadcast on SwapFacility:", swapFacility_);
    }
}
