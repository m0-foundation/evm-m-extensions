// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldToOne } from "../../src/MYieldToOne.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract MYieldToOneIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    function setUp() external {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        _fundAccounts();

        _mYieldToOne = new MYieldToOne(address(_mToken), address(_registrar), _yieldRecipient);
    }

    function test_integration_constants() external view {
        // Check the contract's name, symbol, and decimals
        assertEq(_mYieldToOne.name(), "HALO USD");
        assertEq(_mYieldToOne.symbol(), "HUSD");
        assertEq(_mYieldToOne.decimals(), 6);

        // Check the initial state of the contract
        assertEq(_mYieldToOne.mToken(), address(_mToken));
        assertEq(_mYieldToOne.registrar(), address(_registrar));
        assertEq(_mYieldToOne.yieldRecipient(), _yieldRecipient);
    }

    function test_yieldAccumulationAndClaim() external {
        uint256 amount = 10e6;

        // set fixed timestamp
        vm.warp(1743936851);

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

        // TODO: why is rounding error so high?
        assertEq(_mToken.balanceOf(address(_mYieldToOne)), amount - 56); // 44 wei rounding error in favor of user

        // Fast forward 10 days in the future to generate yield
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // yield accrual
        assertEq(_mYieldToOne.yield(), 11321);

        // transfers do not affect yield
        vm.prank(_alice);
        _mYieldToOne.transfer(_bob, amount / 2);

        assertEq(_mYieldToOne.balanceOf(_bob), amount / 2);
        assertEq(_mYieldToOne.balanceOf(_alice), amount / 2);

        // yield accrual
        assertEq(_mYieldToOne.yield(), 11321);

        // unwraps
        _unwrap(_alice, _alice, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertEq(_mYieldToOne.yield(), 11277);

        _unwrap(_bob, _bob, amount / 2);

        // yield stays basically the same (except rounding up error on transfer)
        assertApproxEqAbs(_mYieldToOne.yield(), 11374, 141);

        assertEq(_mYieldToOne.balanceOf(_bob), 0);
        assertEq(_mYieldToOne.balanceOf(_alice), 0);
        assertEq(_mToken.balanceOf(_bob), amount + amount / 2);
        assertEq(_mToken.balanceOf(_alice), amount / 2);

        assertEq(_mToken.balanceOf(_yieldRecipient), 0);

        // claim yield
        _mYieldToOne.claimYield();

        assertApproxEqAbs(_mToken.balanceOf(_yieldRecipient), 11374, 141);
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
        assertEq(_mToken.balanceOf(address(_mYieldToOne)), 10000087);
    }

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
