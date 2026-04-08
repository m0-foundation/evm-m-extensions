// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { ScriptBase } from "../ScriptBase.s.sol";
import { MultiSigBatchBase } from "../../lib/common/script/MultiSigBatchBase.sol";
import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

/**
 * @title ProposeSetPermissionedExtension
 * @notice Proposes a multisig transaction to set an extension as permissioned on SwapFacility.
 * @dev Requires env vars: PRIVATE_KEY, SWAP_FACILITY_ADDRESS, EXTENSION_ADDRESS, SAFE_ADDRESS
 *      Usage: make set-permissioned-extension RPC_URL=<rpc> SWAP_FACILITY_ADDRESS=<addr> EXTENSION_ADDRESS=<addr> SAFE_ADDRESS=<addr>
 */
contract ProposeSetPermissionedExtension is MultiSigBatchBase {
    function run() external {
        address proposer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address swapFacility_ = vm.envAddress("SWAP_FACILITY_ADDRESS");
        address extension_ = vm.envAddress("EXTENSION_ADDRESS");
        address safe_ = vm.envAddress("SAFE_ADDRESS");

        console.log("Chain ID:", block.chainid);
        console.log("SwapFacility:", swapFacility_);
        console.log("Extension:", extension_);
        console.log("Safe multisig:", safe_);
        console.log("Proposer:", proposer_);

        _addToBatch(swapFacility_, abi.encodeCall(ISwapFacility.setPermissionedExtension, (extension_, true)));

        _simulateBatch(safe_);
        _proposeBatch(safe_, proposer_);

        console.log("setPermissionedExtension proposed to multisig.");
    }
}
