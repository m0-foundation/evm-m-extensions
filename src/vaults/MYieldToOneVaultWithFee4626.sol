// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IMYieldToOne } from "../projects/yieldToOne/IMYieldToOne.sol";
import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";
import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { MYieldToOneVaultWithFeeBase, IAsset } from "./MYieldToOneVaultWithFeeBase.sol";

contract MYieldToOneVaultWithFee4626 is MYieldToOneVaultWithFeeBase, ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        IAsset _asset,
        address _admin,
        uint256 _fee
    ) ERC20(_name, _symbol, _asset.decimals()) MYieldToOneVaultWithFeeBase(_asset, _admin, _fee) {}

    function _totalIssued() internal view override returns (uint256) {
        return totalSupply;
    }

    function _issue(address to, uint256 amount) internal override {
        _mint(to, amount);
    }

    function _claim(address owner, uint256 amount) internal override {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - amount;
        }

        _burn(owner, amount);
    }

    function _balanceOf(address owner) internal view override returns (uint256) {
        return balanceOf[owner];
    }
}
