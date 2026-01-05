// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "uniswapv3/v3-periphery/base/Multicall.sol";

import "uniswapv3/v3-periphery/interfaces/IMulticallExtended.sol";
import "uniswapv3/v3-periphery/base/PeripheryValidationExtended.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract MulticallExtended is IMulticallExtended, Multicall, PeripheryValidationExtended {
    /// @inheritdoc IMulticallExtended
    function multicall(
        uint256 deadline,
        bytes[] calldata data
    ) external payable override checkDeadline(deadline) returns (bytes[] memory) {
        return multicall(data);
    }

    /// @inheritdoc IMulticallExtended
    function multicall(
        bytes32 previousBlockhash,
        bytes[] calldata data
    ) external payable override checkPreviousBlockhash(previousBlockhash) returns (bytes[] memory) {
        return multicall(data);
    }
}
