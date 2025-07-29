// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";  

contract ScriptBase is Script {

      struct Deployments {
        address swapAdapter;
        address swapFacility;
    }

    function _deployOutputPath(uint256 chainId_) internal view returns (string memory) {
        return string.concat(vm.projectRoot(), "/deployments/", vm.toString(chainId_), ".json");
    }

  function _writeDeployment(
      uint256 chainId_,
      string memory key_,
      address value_
  ) internal {
      string memory root = "";

      Deployments memory deployments_ = _readDeployment(chainId_);

      vm.serializeAddress(root, "swapAdapter",
        keccak256(bytes(key_)) == keccak256("swapAdapter") 
          ? value_ : deployments_.swapAdapter);

      vm.writeJson(
        vm.serializeAddress(root, "swapFacility", 
          keccak256(bytes(key_)) == keccak256("swapFacility") 
            ? value_ : deployments_.swapFacility),
        _deployOutputPath(chainId_)
      );

  }

  function _readDeployment(uint256 chainId_)
    internal view
    returns (Deployments memory)
  {
      if (!vm.isFile(_deployOutputPath(chainId_))) {
          revert("Deployment artifacts not found");
      }

      bytes memory data = vm.parseJson(vm.readFile(_deployOutputPath(chainId_)));
      return abi.decode(data, (Deployments));
  }

  function _getMToken() internal pure returns (address) {
    return 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
  }

  function _getWrappedMToken () internal pure returns (address) {
    return 0x437cc33344a0B27A429f795ff6B469C72698B291;
  }

  function _getRegistrar() internal pure returns (address) {
    return 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;
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
