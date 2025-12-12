// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { SwapFacility } from "../../src/swap/SwapFacility.sol";
import { JMIExtension } from "../../src/projects/jmi/JMIExtension.sol";

import { ScriptBase } from "../ScriptBase.s.sol";
import { UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract UpgradeBase is ScriptBase {
    function _upgradeSwapFacility(address swapFacility, address pauser) internal {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        SwapFacility implementation = new SwapFacility(config.mToken, config.registrar);
        UnsafeUpgrades.upgradeProxy(
            swapFacility,
            address(implementation),
            abi.encodeWithSelector(SwapFacility.initializeV2.selector, pauser)
        );
    }

    function _upgradeJMIExtension(address jmiExtension) internal {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        JMIExtension implementation = new JMIExtension(config.mToken, _getSwapFacility());
        UnsafeUpgrades.upgradeProxy(jmiExtension, address(implementation), "");
    }
}
