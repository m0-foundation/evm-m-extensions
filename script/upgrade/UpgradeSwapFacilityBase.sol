pragma solidity 0.8.26;

import { ERC1967Proxy } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { console } from "forge-std/console.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

import { Migrator } from "./Migrator.sol";

import { ScriptBase } from "../ScriptBase.s.sol";

contract UpgradeSwapFacilityBase is ScriptBase {
    function _upgradeSwapFacility(
      address swapFacility_
    ) internal {
      SwapFacility implementation_ = new SwapFacility(_getMToken(), _getRegistrar());
      Migrator migrator_ = new Migrator(address(implementation_));

      console.log("swapFacility", swapFacility_);

      SwapFacility(swapFacility_).migrate(address(migrator_));
    }
}