// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldFee } from "../../src/MYieldFee.sol";

import { IMYieldFee } from "../../src/interfaces/IMYieldFee.sol";
import { IMExtension } from "../../src/interfaces/IMExtension.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../lib/common/src/interfaces/IERC20Extended.sol";

import { BaseUnitTest } from "../utils/BaseUnitTest.sol";

contract MYieldFeeUnitTests is BaseUnitTest {
    MYieldFee internal _mYieldFee;

    // function setUp() public override {
    //     super.setUp();
    //
    //     _mYieldFee = new MYieldFee(address(_mToken), address(_registrar), _yieldRecipient);
    // }

    /* ============ constructor ============ */
    // function test_constructor() external view {
    //     assertEq(_mYieldFee.mToken(), address(_mToken));
    //     assertEq(_mYieldFee.registrar(), address(_registrar));
    //     assertEq(_mYieldFee.yieldRecipient(), _yieldRecipient);
    //     assertEq(_mYieldFee.name(), "HALO USD");
    //     assertEq(_mYieldFee.symbol(), "HUSD");
    //     assertEq(_mYieldFee.decimals(), 6);
    // }
    //
    // function test_constructor_zeroMToken() external {
    //     vm.expectRevert(IMExtension.ZeroMToken.selector);
    //     new MYieldFee(address(0), address(_registrar), address(_yieldRecipient));
    // }
    // function test_constructor_zeroRegistrar() external {
    //     vm.expectRevert(IMExtension.ZeroRegistrar.selector);
    //     new MYieldFee(address(_mToken), address(0), address(_yieldRecipient));
    // }
    //
    // function test_constructor_zeroYieldRecipient() external {
    //     vm.expectRevert(IMYieldFee.ZeroYieldRecipient.selector);
    //     new MYieldFee(address(_mToken), address(_registrar), address(0));
    // }
}
