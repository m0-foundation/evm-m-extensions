// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import {
    ITransparentUpgradeableProxy
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

import { ScriptBase } from "../ScriptBase.s.sol";
import { UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract UpgradeSwapFacilityBase is ScriptBase {
    function _upgradeSwapFacility(address swapFacility_) internal {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        SwapFacility implementation_ = new SwapFacility(config.mToken, config.registrar);
        UnsafeUpgrades.upgradeProxy(swapFacility_, address(implementation_), "");
    }
}
