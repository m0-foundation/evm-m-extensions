pragma solidity 0.8.26;

import { ERC1967Proxy } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { console } from "forge-std/console.sol";

import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";

import { Migrator } from "./Migrator.sol";

import { ScriptBase } from "../ScriptBase.s.sol";

contract UpgradeSwapAdapterBase is ScriptBase {
    function _upgradeSwapAdapter(
      address swapAdapter_
    ) internal {
      UniswapV3SwapAdapter implementation_ = new UniswapV3SwapAdapter(
        _getWrappedMToken(), _getSwapFacility(), _getUniswapRouter()
      );

      Migrator migrator_ = new Migrator(address(implementation_));

      UniswapV3SwapAdapter(swapAdapter_).migrate(address(migrator_));
    }
}