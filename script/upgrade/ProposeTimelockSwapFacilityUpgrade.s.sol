// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ProposeTimelockUpgradeBase } from "./ProposeTimelockUpgradeBase.sol";

contract ProposeTimelockSwapFacilityUpgrade is ProposeTimelockUpgradeBase {
    function run() external {
        address proposer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address safeMultisig = vm.envAddress("SAFE_ADDRESS");
        address timelock = vm.envAddress("TIMELOCK_ADDRESS");
        address pauser = vm.envAddress("PAUSER");

        Deployments memory deployments = _readDeployment(block.chainid);

        require(deployments.swapFacility != address(0), "SwapFacility not deployed on this chain");

        _proposeTimelockSwapFacilityUpgrade(proposer, safeMultisig, timelock, deployments.swapFacility, pauser);
    }
}
