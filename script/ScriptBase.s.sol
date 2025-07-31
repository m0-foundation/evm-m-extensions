// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { Config } from "./Config.sol";

contract ScriptBase is Script, Config {
    string extensionName;

    struct Deployments {
        address[] extensionAddresses;
        string[] extensionNames;
        address swapAdapter;
        address swapFacility;
    }

    function _setExtensionName(string memory extensionName_) internal {
        extensionName = extensionName_;
    }

    function _getExtensionName() internal view returns (string memory) {
        return extensionName;
    }

    function _setExtensionDeployment(
        Deployments memory deployments_,
        string memory key_,
        address value_
    ) internal pure returns (Deployments memory) {
        bool append = true;
        for (uint256 i = 0; i < deployments_.extensionNames.length; i++) {
            if (keccak256(bytes(deployments_.extensionNames[i])) == keccak256(bytes(key_))) {
                deployments_.extensionNames[i] = key_;
                deployments_.extensionAddresses[i] = value_;
                append = false;
                break;
            }
        }

        if (append) {
            string[] memory nameReplacements = new string[](deployments_.extensionNames.length + 1);
            address[] memory addressReplacements = new address[](deployments_.extensionNames.length + 1);

            for (uint256 i = 0; i < deployments_.extensionNames.length; i++) {
                nameReplacements[i] = deployments_.extensionNames[i];
                addressReplacements[i] = deployments_.extensionAddresses[i];
            }

            nameReplacements[nameReplacements.length - 1] = key_;
            addressReplacements[addressReplacements.length - 1] = value_;

            deployments_.extensionNames = nameReplacements;
            deployments_.extensionAddresses = addressReplacements;
        }

        return deployments_;
    }

    function _deployOutputPath(uint256 chainId_) internal view returns (string memory) {
        return string.concat(vm.projectRoot(), "/deployments/", vm.toString(chainId_), ".json");
    }

    function _writeDeployment(uint256 chainId_, string memory key_, address value_) internal {
        string memory root = "";

        Deployments memory deployments_ = _readDeployment(chainId_);

        deployments_ = _setExtensionDeployment(deployments_, key_, value_);

        vm.serializeAddress(
            root,
            "swapAdapter",
            keccak256(bytes(key_)) == keccak256("swapAdapter") ? value_ : deployments_.swapAdapter
        );

        vm.serializeAddress(
            root,
            "swapFacility",
            keccak256(bytes(key_)) == keccak256("swapFacility") ? value_ : deployments_.swapFacility
        );

        vm.serializeString(root, "extensionNames", deployments_.extensionNames);

        vm.writeJson(
            vm.serializeAddress(root, "extensionAddresses", deployments_.extensionAddresses),
            _deployOutputPath(chainId_)
        );
    }

    function _readDeployment(uint256 chainId_) internal view returns (Deployments memory) {
        if (!vm.isFile(_deployOutputPath(chainId_))) {
            revert("Deployment artifacts not found");
        }

        bytes memory data = vm.parseJson(vm.readFile(_deployOutputPath(chainId_)));

        return abi.decode(data, (Deployments));
    }

    function _getSwapFacility() internal view returns (address) {
        Deployments memory deployments_ = _readDeployment(block.chainid);
        return deployments_.swapFacility;
    }

    function _getName() internal view returns (string memory) {
        return vm.envString("NAME");
    }

    function _getSymbol() internal view returns (string memory) {
        return vm.envString("SYMBOL");
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
