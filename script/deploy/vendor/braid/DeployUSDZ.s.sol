// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { console } from "../../../../lib/forge-std/src/console.sol";

import { DeployUSDZBase } from "./DeployUSDZBase.sol";

contract DeployUSDZ is DeployUSDZBase {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        console.log("ADMIN: %s", admin);

        vm.startBroadcast(deployer);

        (address implementation, address proxy, address proxyAdmin) = _deployUSDZ(
            deployer,
            M_TOKEN,
            SWAP_FACILITY,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            pauser,
            forcedTransferManager
        );

        vm.stopBroadcast();

        console.log("USDZ successfully deployed on chain ID %s: ", block.chainid);
        console.log("Implementation: %s", implementation);
        console.log("Proxy: %s", proxy);
        console.log("ProxyAdmin: %s", proxyAdmin);
    }
}
