// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../lib/forge-std/src/console.sol";
import {
    AccessControl
} from "../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import { ScriptBase } from "./ScriptBase.s.sol";
import { MultiSigBatchBase } from "../lib/common/script/MultiSigBatchBase.sol";
import {
    Ownable
} from "../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title ProposeTransferSwapFacilityOwner
 * @notice Script to transfer swap facility ownership to timelock controller
 * @dev This script transfers the DEFAULT_ADMIN_ROLE of the swap facility to a new owner (timelock)
 */
contract ProposeTransferSwapFacilityOwner is MultiSigBatchBase {
    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;
    address constant _PROXY_ADMIN = 0x0f38D8A5583f9316084E9c40737244870c565924;
    address constant _MAINNET_TIMELOCK = 0x23CA665c8a73292Fc7AC2cC4493d2cE883BBA468;

    // TransparentProxy address of SwapFacility on mainnet
    address constant _SWAP_FACILITY = 0xB6807116b3B1B321a390594e31ECD6e0076f6278;

    function run() external {
        address proposer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        bytes32 DEFAULT_ADMIN_ROLE = AccessControl(_SWAP_FACILITY).DEFAULT_ADMIN_ROLE();

        require(_MAINNET_TIMELOCK != address(0), "New owner cannot be zero address");
        console.log("Current chain ID:", block.chainid);
        console.log("ProxyAdmin address:", _PROXY_ADMIN);
        console.log("Multisig address:", _SAFE_MULTISIG);
        console.log("SwapFacility address:", _SWAP_FACILITY);
        console.log("New owner (timelock):", _MAINNET_TIMELOCK);
        console.log("Proposer:", proposer_);

        // transfer proxyAdmin ownership to newOwner_
        _addToBatch(_PROXY_ADMIN, abi.encodeCall(Ownable.transferOwnership, (_MAINNET_TIMELOCK)));

        // transfer swap facility DEFAULT_ADMIN_ROLE to newOwner_
        _addToBatch(_SWAP_FACILITY, abi.encodeCall(AccessControl.grantRole, (DEFAULT_ADMIN_ROLE, _MAINNET_TIMELOCK)));

        // renounce swap facility DEFAULT_ADMIN_ROLE from Multisig
        _addToBatch(_SWAP_FACILITY, abi.encodeCall(AccessControl.renounceRole, (DEFAULT_ADMIN_ROLE, _SAFE_MULTISIG)));

        console.log("SwapFacility ownership transfer proposed.");
    }
}
