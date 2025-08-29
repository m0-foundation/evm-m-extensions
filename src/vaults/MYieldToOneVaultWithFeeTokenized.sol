// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IMYieldToOne } from "../projects/yieldToOne/IMYieldToOne.sol";
import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {
    ERC20Upgradeable
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { MYieldToOneVaultWithFeeBase, IAsset } from "./MYieldToOneVaultWithFeeBase.sol";

contract MYieldToOneVaultWithFeeTokenized is MYieldToOneVaultWithFeeBase, ERC20Upgradeable {
    constructor(IAsset _asset) MYieldToOneVaultWithFeeBase(_asset) {}

    function initialize(string memory _name, string memory _symbol, address _admin, uint256 _fee) public initializer {
        __ERC20_init(_name, _symbol);
        __MYieldToOneVaultWithFeeBase_init(_admin, _fee);
    }

    function decimals() public view override returns (uint8) {
        return ASSET.decimals();
    }

    function _totalIssued() internal view override returns (uint256) {
        return totalSupply();
    }

    function _issue(address to, uint256 amount) internal override {
        _mint(to, amount);
    }

    function _claim(address owner, uint256 amount) internal override {
        if (msg.sender != owner) _spendAllowance(owner, msg.sender, amount);

        _burn(owner, amount);
    }

    function _balanceOf(address owner) internal view override returns (uint256) {
        return balanceOf(owner);
    }
}
