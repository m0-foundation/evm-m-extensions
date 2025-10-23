// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import { MExtension } from "../../src/MExtension.sol";

contract MExtensionHarness is MExtension {
    mapping(address account => uint256 balance) internal _balanceOf;
    uint256 internal _totalSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MExtension(mToken, swapFacility) {}

    function initialize(string memory name, string memory symbol) public initializer {
        __MExtension_init(name, symbol);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address recipient, uint256 amount) internal override {
        _balanceOf[recipient] += amount;
    }

    function _burn(address account, uint256 amount) internal override {
        _balanceOf[account] -= amount;
    }

    function _update(address sender, address recipient, uint256 amount) internal override {
        _balanceOf[sender] -= amount;
        _balanceOf[recipient] += amount;
    }

    function setBalanceOf(address account, uint256 amount) external {
        _balanceOf[account] = amount;
    }
}
