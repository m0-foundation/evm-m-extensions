// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IMYieldToOne } from "../projects/yieldToOne/IMYieldToOne.sol";
import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";
import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { MYieldToOneVaultWithFeeBase, IAsset } from "./MYieldToOneVaultWithFeeBase.sol";

contract MYieldToOneVaultWithFeeNoToken is MYieldToOneVaultWithFeeBase {
    error OnlyHolder();

    uint256 public balancesTotal;

    mapping(address => uint256) public balances;

    constructor(IAsset _asset, address _admin, uint256 _fee) MYieldToOneVaultWithFeeBase(_asset, _admin, _fee) {}

    function _totalIssued() internal view override returns (uint256) {
        return balancesTotal;
    }

    function _issue(address to, uint256 amount) internal override {
        balances[to] += amount;
    }

    function _claim(address from, uint256 amount) internal override {
        if (from != msg.sender) revert OnlyHolder();

        balances[from] -= amount;
    }

    function _balanceOf(address owner) internal view override returns (uint256) {
        return balances[owner];
    }
}
