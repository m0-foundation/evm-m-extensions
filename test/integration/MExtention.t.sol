// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";

import { MExtensionHarness } from "../harness/MExtensionHarness.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract MExtensionIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    function setUp() public override {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_482_175);

        super.setUp();

        _fundAccounts();

        mExtension = MExtensionHarness(
            Upgrades.deployTransparentProxy(
                "MExtensionHarness.sol:MExtensionHarness",
                admin,
                abi.encodeWithSelector(MExtensionHarness.initialize.selector, NAME, SYMBOL),
                mExtensionDeployOptions
            )
        );
    }

    function test_integration_constants() external view {
        assertEq(mExtension.name(), NAME);
        assertEq(mExtension.symbol(), SYMBOL);
        assertEq(mExtension.decimals(), 6);
        assertEq(mExtension.mToken(), address(mToken));
        assertEq(mExtension.swapFacility(), address(swapFacility));
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_notApprovedEarner() external {
        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.NotApprovedEarner.selector));
        mExtension.enableEarning();
    }

    function test_enableEarning() external {
        _addToList(EARNERS_LIST, address(mExtension));

        mExtension.enableEarning();

        assertTrue(mExtension.isEarningEnabled());
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_approvedEarner() external {
        _addToList(EARNERS_LIST, address(mExtension));
        mExtension.enableEarning();

        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.IsApprovedEarner.selector));
        mExtension.disableEarning();
    }

    function test_disableEarning() external {
        _addToList(EARNERS_LIST, address(mExtension));
        mExtension.enableEarning();

        _removeFromList(EARNERS_LIST, address(mExtension));

        mExtension.disableEarning();

        assertFalse(mExtension.isEarningEnabled());
    }

    /* ============ wrap ============ */

    function test_wrap() external {
        _addToList(EARNERS_LIST, address(mExtension));

        assertEq(mToken.balanceOf(alice), 10e6);

        _swapInM(address(mExtension), alice, alice, 5e6);

        assertEq(mExtension.balanceOf(alice), 5e6);
        assertEq(mToken.balanceOf(alice), 5e6);

        _swapInM(address(mExtension), alice, alice, 5e6);

        assertEq(mExtension.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(alice), 0);
    }

    function test_wrap_withPermits() external {
        _addToList(EARNERS_LIST, address(mExtension));

        assertEq(mToken.balanceOf(alice), 10e6);

        _swapInMWithPermitVRS(address(mExtension), alice, aliceKey, alice, 5e6, 0, block.timestamp);

        assertEq(mExtension.balanceOf(alice), 5e6);
        assertEq(mToken.balanceOf(alice), 5e6);

        _swapInMWithPermitSignature(address(mExtension), alice, aliceKey, alice, 5e6, 1, block.timestamp);

        assertEq(mExtension.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(alice), 0);
    }

    /* ============ unwrap ============ */

    function test_unwrap() external {
        _addToList(EARNERS_LIST, address(mExtension));

        _giveM(address(mExtension), 10e6);
        mExtension.setBalanceOf(alice, 10e6);

        assertEq(mExtension.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(address(mExtension)), 10e6);

        _swapMOut(address(mExtension), alice, alice, 5e6);

        assertEq(mExtension.balanceOf(alice), 5e6);
        assertEq(mToken.balanceOf(alice), 15e6);
        assertEq(mToken.balanceOf(address(mExtension)), 5e6);

        _swapMOut(address(mExtension), alice, alice, 5e6);

        assertEq(mExtension.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 20e6);
        assertEq(mToken.balanceOf(address(mExtension)), 0);
    }
}
