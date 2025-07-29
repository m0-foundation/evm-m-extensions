// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployBase } from "./DeployBase.s.sol";  

import { Upgrades, Options } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";

contract DeploySwapAdapterBase is DeployBase {

    string internal constant _SWAP_ADAPTER_CONTRACT_NAME = "Unis12345SwapAdapter";

    function _deploySwapAdapter(
        uint256 chainId_,
        address deployer_
    ) internal returns (address) {
        UniswapV3SwapAdapter implementation_ = new UniswapV3SwapAdapter(
            _getWrappedMToken(), _getSwapFacility(), _getUniswapRouter()
        );
        address[] memory whitelistedTokens_ = new address[](0);
        bytes memory initializeCall = abi.encodeCall(UniswapV3SwapAdapter.initialize, (deployer_, whitelistedTokens_));
        return _deployCreate3Proxy(address(implementation_), _computeSalt(deployer_, _SWAP_ADAPTER_CONTRACT_NAME), initializeCall);
    }

}