// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";  

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";

contract DeploySwapFacilityBase is DeployBase {

    string internal constant _SWAP_FACILITY_CONTRACT_NAME = "SwapFacility";

    function _deploySwapFacility(
        uint256 chainId_,
        address deployer_
    ) internal returns (address) {
        SwapFacility implementation_ = new SwapFacility(_getMToken(), _getRegistrar());
        bytes memory initializeCall = abi.encodeCall(ISwapFacility.initialize, (deployer_));
        return _deployCreate3Proxy(address(implementation_), _computeSalt(deployer_, _SWAP_FACILITY_CONTRACT_NAME), initializeCall);
    }

}