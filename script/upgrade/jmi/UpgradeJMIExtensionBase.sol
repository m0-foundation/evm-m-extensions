// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { JMIExtension } from "../../../src/projects/jmi/JMIExtension.sol";

import { ScriptBase } from "../../ScriptBase.s.sol";
import { UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract UpgradeJMIExtensionBase is ScriptBase {
    function _upgradeJMIExtension(address jmiExtension) internal {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        JMIExtension implementation = new JMIExtension(config.mToken, _getSwapFacility());
        UnsafeUpgrades.upgradeProxy(jmiExtension, address(implementation), "");
    }
}
