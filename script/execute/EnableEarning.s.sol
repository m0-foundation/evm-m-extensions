// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { ScriptBase } from "../ScriptBase.s.sol";
import { IMExtension } from "../../src/interfaces/IMExtension.sol";

/**
 * @title EnableEarning
 * @notice Script to enable earning on a deployed MExtension contract.
 * @dev Requires env vars: PRIVATE_KEY, EXTENSION_ADDRESS
 *      Usage: make enable-earning RPC_URL=<rpc> EXTENSION_ADDRESS=<proxy>
 */
contract EnableEarning is ScriptBase {
    function run() external {
        address extensionAddress = vm.envAddress("EXTENSION_ADDRESS");

        console.log("Enabling earning on extension:", extensionAddress);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        IMExtension(extensionAddress).enableEarning();

        vm.stopBroadcast();

        console.log("Earning enabled on extension:", extensionAddress);
    }
}
