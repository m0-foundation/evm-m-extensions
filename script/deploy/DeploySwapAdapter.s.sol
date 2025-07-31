// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";
import { console } from "forge-std/console.sol";

contract DeploySwapAdapter is DeployBase {
    function run(string memory extensionName) public {
        require(keccak256(bytes(extensionName)) != keccak256(""), "Run script with EXTENSION_NAME=...");

        _setExtensionName(extensionName);

        address deployer_ = vm.addr(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();

        address swapAdater = _deploySwapAdapter(deployer_, deployer_);

        vm.stopBroadcast();

        console.log("SwapAdapter:", swapAdater);

        _writeDeployment(block.chainid, "swapAdapter", swapAdater);
    }
}
