// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

import { ScriptBase } from "../ScriptBase.s.sol";
import { UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract UpgradeSwapFacilityBase is ScriptBase {
    function _upgradeSwapFacility(address swapFacility, address pauser) internal {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        SwapFacility implementation = new SwapFacility(config.mToken, config.registrar);
        UnsafeUpgrades.upgradeProxy(
            swapFacility,
            address(implementation),
            abi.encodeWithSelector(SwapFacility.initializeV2.selector, pauser)
        );
    }
}
