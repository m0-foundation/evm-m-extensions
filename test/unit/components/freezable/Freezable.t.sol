// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IAccessControl } from "../../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IFreezable } from "../../../../src/components/freezable/IFreezable.sol";

import { FreezableHarness } from "../../../harness/FreezableHarness.sol";

import { BaseUnitTest } from "../../../utils/BaseUnitTest.sol";

contract FreezableUnitTests is BaseUnitTest {
    FreezableHarness public freezable;

    function setUp() public override {
        super.setUp();

        freezable = FreezableHarness(
            Upgrades.deployTransparentProxy(
                "FreezableHarness.sol:FreezableHarness",
                admin,
                abi.encodeWithSelector(FreezableHarness.initialize.selector, freezeManager)
            )
        );
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertTrue(IAccessControl(address(freezable)).hasRole(FREEZE_MANAGER_ROLE, freezeManager));
    }

    function test_initialize_zeroFreezeManager() external {
        address implementation = address(new FreezableHarness());

        vm.expectRevert(IFreezable.ZeroFreezeManager.selector);
        UnsafeUpgrades.deployTransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(FreezableHarness.initialize.selector, address(0))
        );
    }

    /* ============ freeze ============ */

    function test_freeze_onlyFreezeManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, FREEZE_MANAGER_ROLE)
        );

        vm.prank(alice);
        freezable.freeze(bob);
    }

    function test_freeze_returnEarlyIfFrozen() public {
        vm.expectEmit();
        emit IFreezable.Frozen(alice, block.timestamp);

        vm.prank(freezeManager);
        freezable.freeze(alice);

        assertTrue(freezable.isFrozen(alice));

        vm.prank(freezeManager);
        freezable.freeze(alice);

        assertTrue(freezable.isFrozen(alice));
    }

    function test_freeze() public {
        vm.expectEmit();
        emit IFreezable.Frozen(alice, block.timestamp);

        vm.prank(freezeManager);
        freezable.freeze(alice);

        assertTrue(freezable.isFrozen(alice));
    }

    /* ============ freezeAccounts ============ */

    function test_freezeAccounts_onlyFreezeManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, FREEZE_MANAGER_ROLE)
        );

        vm.prank(alice);
        freezable.freezeAccounts(accounts);
    }

    function test_freezeAccounts_returnEarlyIfFrozen() public {
        address[] memory accounts = new address[](2);
        accounts[0] = alice;
        accounts[1] = alice;

        vm.expectEmit();
        emit IFreezable.Frozen(alice, block.timestamp);

        vm.prank(freezeManager);
        freezable.freezeAccounts(accounts);
    }

    function test_freezeAccounts() public {
        for (uint256 i; i < accounts.length; ++i) {
            vm.expectEmit();
            emit IFreezable.Frozen(accounts[i], block.timestamp);
        }

        vm.prank(freezeManager);
        freezable.freezeAccounts(accounts);

        for (uint256 i; i < accounts.length; ++i) {
            assertTrue(freezable.isFrozen(accounts[i]));
        }
    }

    /* ============ unfreeze ============ */

    function test_unfreeze_onlyFreezeManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, FREEZE_MANAGER_ROLE)
        );

        vm.prank(alice);
        freezable.unfreeze(bob);
    }

    function test_freeze_returnEarlyIfNotFrozen() public {
        assertFalse(freezable.isFrozen(alice));

        vm.prank(freezeManager);
        freezable.unfreeze(alice);

        assertFalse(freezable.isFrozen(alice));
    }

    function test_unfreeze() public {
        vm.prank(freezeManager);
        freezable.freeze(alice);

        assertTrue(freezable.isFrozen(alice));

        vm.expectEmit();
        emit IFreezable.Unfrozen(alice, block.timestamp);

        vm.prank(freezeManager);
        freezable.unfreeze(alice);

        assertFalse(freezable.isFrozen(alice));
    }

    /* ============ unfreezeAccounts ============ */

    function test_unfreezeAccounts_onlyFreezeManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, FREEZE_MANAGER_ROLE)
        );

        vm.prank(alice);
        freezable.unfreezeAccounts(accounts);
    }

    function test_unfreezeAccounts_returnEarlyIfNotFrozen() public {
        vm.prank(freezeManager);
        freezable.freeze(alice);

        assertTrue(freezable.isFrozen(alice));
        assertFalse(freezable.isFrozen(bob));

        address[] memory accounts = new address[](2);
        accounts[0] = alice;
        accounts[1] = bob;

        vm.expectEmit();
        emit IFreezable.Unfrozen(alice, block.timestamp);

        vm.prank(freezeManager);
        freezable.unfreezeAccounts(accounts);

        assertFalse(freezable.isFrozen(alice));
        assertFalse(freezable.isFrozen(bob));
    }

    function test_unfreezeAccounts() public {
        vm.prank(freezeManager);
        freezable.freezeAccounts(accounts);

        for (uint256 i; i < accounts.length; ++i) {
            vm.expectEmit();
            emit IFreezable.Unfrozen(accounts[i], block.timestamp);
        }

        vm.prank(freezeManager);
        freezable.unfreezeAccounts(accounts);

        for (uint256 i; i < accounts.length; ++i) {
            assertFalse(freezable.isFrozen(accounts[i]));
        }
    }

    /* ============ _revertIfFrozen ============ */

    function test_revertIfFrozen() public {
        vm.prank(freezeManager);
        freezable.freeze(alice);

        assertTrue(freezable.isFrozen(alice));

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        freezable.revertIfFrozenInternal(alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        freezable.revertIfFrozen(alice);
    }

    /* ============ _revertIfNotFrozen ============ */

    function test_revertIfNotFrozen() public {
        assertFalse(freezable.isFrozen(alice));

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountNotFrozen.selector, alice));

        freezable.revertIfNotFrozenInternal(alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountNotFrozen.selector, alice));

        freezable.revertIfNotFrozen(alice);
    }
}
