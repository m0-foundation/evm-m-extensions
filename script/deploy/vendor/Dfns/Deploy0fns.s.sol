// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { console } from "../../../../lib/forge-std/src/console.sol";

import { Deploy0fnsBase } from "./Deploy0fnsBase.sol";

contract Deploy0fns is Deploy0fnsBase {
    function run() external {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        console.log("ADMIN: %s", ADMIN);

        vm.startBroadcast(deployer);

        (address implementation, address proxy, address proxyAdmin) = _deploy0fns(
            deployer,
            M_TOKEN,
            SWAP_FACILITY,
            NAME,
            SYMBOL,
            ADMIN,
            EARNER_MANAGER,
            FEE_RECIPIENT
        );

        vm.stopBroadcast();

        console.log("0fns successfully deployed on chain ID %s: ", block.chainid);
        console.log("Implementation: %s", implementation);
        console.log("Proxy: %s", proxy);
        console.log("ProxyAdmin: %s", proxyAdmin);
    }
}
