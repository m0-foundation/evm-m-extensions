// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ITransparentUpgradeableProxy } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

import { Migrator } from "./Migrator.sol";

import { ScriptBase } from "../ScriptBase.s.sol";

contract UpgradeSwapFacilityBase is ScriptBase {
    function _upgradeSwapFacility(
      address swapFacility_
    ) internal {
      SwapFacility implementation_ = new SwapFacility(_getMToken(), _getRegistrar());

      ITransparentUpgradeableProxy(swapFacility_).upgradeToAndCall(address(implementation_), "");
    }
}