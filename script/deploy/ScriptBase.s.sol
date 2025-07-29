// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";  

contract ScriptBase is Script {

  function _getMToken() internal view returns (address) {
    return vm.envAddress("M_TOKEN");
  }

  function _getSwapFacility() internal view returns (address) {
    return vm.envAddress("SWAP_FACILITY");
  }

  function _getName() internal view returns (string memory) {
    return vm.envString("NAME");
  }

  function _getSymbol() internal view returns (string memory) {
    return vm.envString("SYMBOL");
  }

  function _getUniswapRouter() internal view returns (address) {
    return vm.envAddress("UNISWAP_ROUTER");
  }

  function _getRegistrar() internal view returns (address) {
    return vm.envAddress("REGISTRAR");
  }

  function _getEarnerManager() internal view returns (address) {
    return vm.envAddress("EARNER_MANAGER");
  }

  function _getWhitelistedTokens() internal view returns (address[] memory) {
    return vm.envOr("WHITELISTED_TOKENS", ",", new address[](0));
  }

  function _getFeeRate() internal view returns (uint16) {
    return uint16(vm.envUint("FEE_RATE"));
  }

  function _getFeeRecipient() internal view returns (address) {
    return vm.envAddress("FEE_RECIPIENT");
  }

  function _getFeeManager() internal view returns (address) {
    return vm.envAddress("FEE_MANAGER");
  }

  function _getYieldRecipient() internal view returns (address) {
    return vm.envAddress("YIELD_RECIPIENT");
  }

  function _getClaimRecipientManager() internal view returns (address) {
    return vm.envAddress("CLAIM_RECIPIENT_MANAGER");
  }

  function _getAdmin() internal view returns (address) {
    return vm.envAddress("ADMIN");
  }

  function _getBlacklistManager() internal view returns (address) {
    return vm.envAddress("BLACKLIST_MANAGER");
  }

  function _getYieldRecipientManager() internal view returns (address) {
    return vm.envAddress("YIELD_RECIPIENT_MANAGER");
  }

}
