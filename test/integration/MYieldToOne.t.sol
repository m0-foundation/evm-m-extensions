// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";

import { MYieldToOne } from "../../src/MYieldToOne.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract MYieldToOneIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    function setUp() external {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        _fundAccounts();

        _mYieldToOne = new MYieldToOne(
            _NAME,
            _SYMBOL,
            address(_mToken),
            _yieldRecipient,
            _defaultAdmin,
            _blacklistManager,
            _yieldRecipientManager
        );
    }

    function test_integration_constants() external view {
        // Check the contract's name, symbol, and decimals
        assertEq(_mYieldToOne.name(), _NAME);
        assertEq(_mYieldToOne.symbol(), _SYMBOL);
        assertEq(_mYieldToOne.decimals(), 6);

        // Check the initial state of the contract
        assertEq(_mYieldToOne.mToken(), address(_mToken));
        assertEq(_mYieldToOne.yieldRecipient(), _yieldRecipient);
    }

    function test_yieldAccumulationAndClaim() external {
        uint256 amount = 10e6;

        // Enable earning for the contract
        _addToList(_EARNERS_LIST, address(_mYieldToOne));
        _mYieldToOne.enableEarning();

        // Check the initial earning state
        assertEq(_mToken.isEarning(address(_mYieldToOne)), true);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        // wrap from non-earner account
        _wrap(_alice, _alice, amount);

        // Check balances of MYieldToOne and Alice after wrapping
        assertEq(_mYieldToOne.balanceOf(_alice), amount); // user receives exact amount
        assertApproxEqAbs(_mToken.balanceOf(address(_mYieldToOne)), amount, 2); // rounds down

        // Fast forward 10 days in the future to generate yield
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // yield accrual
        assertApproxEqAbs(_mYieldToOne.yield(), 11375, 1); // may round up

        // transfers do not affect yield
        vm.prank(_alice);
        _mYieldToOne.transfer(_bob, amount / 2);

        assertEq(_mYieldToOne.balanceOf(_bob), amount / 2);
        assertEq(_mYieldToOne.balanceOf(_alice), amount / 2);

        // yield accrual
        assertApproxEqAbs(_mYieldToOne.yield(), 11375, 1);

        // unwraps
        _unwrap(_alice, _alice, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertApproxEqAbs(_mYieldToOne.yield(), 11375, 2);

        _unwrap(_bob, _bob, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertApproxEqAbs(_mYieldToOne.yield(), 11375, 1);

        assertEq(_mYieldToOne.balanceOf(_bob), 0);
        assertEq(_mYieldToOne.balanceOf(_alice), 0);
        assertEq(_mToken.balanceOf(_bob), amount + amount / 2);
        assertEq(_mToken.balanceOf(_alice), amount / 2);

        assertEq(_mToken.balanceOf(_yieldRecipient), 0);

        // claim yield
        _mYieldToOne.claimYield();

        assertApproxEqAbs(_mToken.balanceOf(_yieldRecipient), 11375, 1);
        assertEq(_mYieldToOne.yield(), 0);
        assertEq(_mToken.balanceOf(address(_mYieldToOne)), 0);
        assertEq(_mYieldToOne.totalSupply(), 0);

        // wrap from earner account
        _addToList(_EARNERS_LIST, _bob);

        vm.prank(_bob);
        _mToken.startEarning();

        _wrap(_bob, _bob, amount);

        // Check balances of MYieldToOne and Bob after wrapping
        assertEq(_mYieldToOne.balanceOf(_bob), amount);
        assertEq(_mToken.balanceOf(address(_mYieldToOne)), 10000146);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_notApprovedEarner() external {
        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.NotApprovedEarner.selector));
        _mYieldToOne.enableEarning();
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_approvedEarner() external {
        _addToList(_EARNERS_LIST, address(_mYieldToOne));
        _mYieldToOne.enableEarning();

        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.IsApprovedEarner.selector));
        _mYieldToOne.disableEarning();
    }

    /* ============ _wrap ============ */

    function test_wrapWithPermits() external {
        assertEq(_mToken.balanceOf(_alice), 10e6);

        _wrapWithPermitVRS(_alice, _aliceKey, _alice, 5e6, 0, block.timestamp);

        assertEq(_mYieldToOne.balanceOf(_alice), 5e6);
        assertEq(_mToken.balanceOf(_alice), 5e6);

        _wrapWithPermitVRS(_alice, _aliceKey, _alice, 5e6, 1, block.timestamp);

        assertEq(_mYieldToOne.balanceOf(_alice), 10e6);
        assertEq(_mToken.balanceOf(_alice), 0);
    }
}
