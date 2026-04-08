// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { ScriptBase } from "../ScriptBase.s.sol";
import { MultiSigBatchBase } from "../../lib/common/script/MultiSigBatchBase.sol";
import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

/**
 * @title ProposeSetPermissionedMSwapper
 * @notice Proposes a multisig transaction to set a permissioned MSwapper on SwapFacility.
 * @dev Requires env vars: PRIVATE_KEY, SWAP_FACILITY_ADDRESS, EXTENSION_ADDRESS, SWAPPER_ADDRESS, SAFE_ADDRESS
 *      Usage: make set-permissioned-mswapper RPC_URL=<rpc> SWAP_FACILITY_ADDRESS=<addr> EXTENSION_ADDRESS=<addr> SWAPPER_ADDRESS=<addr> SAFE_ADDRESS=<addr>
 */
contract ProposeSetPermissionedMSwapper is MultiSigBatchBase {
    function run() external {
        address proposer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address swapFacility_ = vm.envAddress("SWAP_FACILITY_ADDRESS");
        address extension_ = vm.envAddress("EXTENSION_ADDRESS");
        address swapper_ = vm.envAddress("SWAPPER_ADDRESS");
        address safe_ = vm.envAddress("SAFE_ADDRESS");

        console.log("Chain ID:", block.chainid);
        console.log("SwapFacility:", swapFacility_);
        console.log("Extension:", extension_);
        console.log("Swapper:", swapper_);
        console.log("Safe multisig:", safe_);
        console.log("Proposer:", proposer_);

        _addToBatch(swapFacility_, abi.encodeCall(ISwapFacility.setPermissionedMSwapper, (extension_, swapper_, true)));

        _simulateBatch(safe_);
        _proposeBatch(safe_, proposer_);

        console.log("setPermissionedMSwapper proposed to multisig.");
    }
}
