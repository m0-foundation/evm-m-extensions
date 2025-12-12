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

    function _upgradeOldSwapFacility(address swapFacility) internal {

        // Old m (MONEY) and registrar addresses used in earlier SwapFacility deployment
        address oldMToken = 0x0c941AD94Ca4A52EDAeAbF203b61bdd1807CeEC0;
        address oldRegistrar = 0x975Bf5f212367D09CB7f69D3dc4BA8C9B440aD3A;

        SwapFacility implementation = new SwapFacility(oldMToken, oldRegistrar);

        UnsafeUpgrades.upgradeProxy(
            swapFacility,
            address(implementation),
            // initializeV2 has been called before, so no need to pass data here
            ""
        );
    }

    function _upgradeJMIExtension(address jmiExtension) internal {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        JMIExtension implementation = new JMIExtension(config.mToken, _getSwapFacility());
        UnsafeUpgrades.upgradeProxy(jmiExtension, address(implementation), "");
    }
}
