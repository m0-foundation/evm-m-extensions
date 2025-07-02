// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MExtension } from "../../src/MExtension.sol";

contract MExtensionHarness is MExtension {
    mapping(address account => uint256 balance) internal _balanceOf;
    uint256 internal _totalSupply;

    function initialize(
        string memory name,
        string memory symbol,
        address mToken,
        address swapFacility
    ) public initializer {
        __MExtension_init(name, symbol, mToken, swapFacility);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address recipient, uint256 amount) internal override {}
    function _burn(address account, uint256 amount) internal override {}
    function _update(address sender, address recipient, uint256 amount) internal override {}
}
