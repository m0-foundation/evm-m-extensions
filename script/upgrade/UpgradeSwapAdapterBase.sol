// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ITransparentUpgradeableProxy } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { console } from "forge-std/console.sol";

import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";

import { Migrator } from "./Migrator.sol";

import { ScriptBase } from "../ScriptBase.s.sol";

contract UpgradeSwapAdapterBase is ScriptBase {
    function _upgradeSwapAdapter(
      address swapAdapter_
    ) internal {
      UniswapV3SwapAdapter implementation_ = new UniswapV3SwapAdapter(
        WRAPPED_M_TOKEN, _getSwapFacility(), UNISWAP_V3_ROUTER
      );

      ITransparentUpgradeableProxy(swapAdapter_).upgradeToAndCall(address(implementation_), "");
    }
}