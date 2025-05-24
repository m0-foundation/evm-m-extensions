// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import {
    IAccessControl
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IBlacklistable } from "../../../src/interfaces/IBlacklistable.sol";

import { BlacklistableUpgradeableHarness } from "../../harness/BlacklistableUpgradeableHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract BlacklistableUpgradeableUnitTests is BaseUnitTest {
    BlacklistableUpgradeableHarness public blacklistable;

    function setUp() public override {
        super.setUp();

        blacklistable = BlacklistableUpgradeableHarness(
            Upgrades.deployUUPSProxy(
                "BlacklistableUpgradeableHarness.sol:BlacklistableUpgradeableHarness",
                abi.encodeWithSelector(BlacklistableUpgradeableHarness.initialize.selector, blacklistManager)
            )
        );
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertTrue(IAccessControl(address(blacklistable)).hasRole(BLACKLIST_MANAGER_ROLE, blacklistManager));
    }

    function test_initialize_zeroBlacklistManager() external {
        address implementation = address(new BlacklistableUpgradeableHarness());

        vm.expectRevert(IBlacklistable.ZeroBlacklistManager.selector);
        UnsafeUpgrades.deployUUPSProxy(
            implementation,
            abi.encodeWithSelector(BlacklistableUpgradeableHarness.initialize.selector, address(0))
        );
    }

    /* ============ blacklist ============ */

    function test_blacklist_onlyBlacklistManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                BLACKLIST_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        blacklistable.blacklist(bob);
    }

    function test_blacklist_revertIfBlacklisted() public {
        vm.prank(blacklistManager);
        blacklistable.blacklist(alice);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, alice));

        vm.prank(blacklistManager);
        blacklistable.blacklist(alice);
    }

    function test_blacklist() public {
        vm.expectEmit();
        emit IBlacklistable.Blacklisted(alice, block.timestamp);

        vm.prank(blacklistManager);
        blacklistable.blacklist(alice);

        assertTrue(blacklistable.isBlacklisted(alice));
    }

    /* ============ blacklistAccounts ============ */

    function test_blacklistAccounts_onlyBlacklistManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                BLACKLIST_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        blacklistable.blacklistAccounts(accounts);
    }

    function test_blacklistAccounts_revertIfBlacklisted() public {
        address[] memory accounts = new address[](2);
        accounts[0] = alice;
        accounts[1] = alice;

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, alice));

        vm.prank(blacklistManager);
        blacklistable.blacklistAccounts(accounts);
    }

    function test_blacklistAccounts() public {
        for (uint256 i; i < accounts.length; ++i) {
            vm.expectEmit();
            emit IBlacklistable.Blacklisted(accounts[i], block.timestamp);
        }

        vm.prank(blacklistManager);
        blacklistable.blacklistAccounts(accounts);

        for (uint256 i; i < accounts.length; ++i) {
            assertTrue(blacklistable.isBlacklisted(accounts[i]));
        }
    }

    /* ============ unblacklist ============ */

    function test_unblacklist_onlyBlacklistManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                BLACKLIST_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        blacklistable.unblacklist(bob);
    }

    function test_blacklist_revertIfNotBlacklisted() public {
        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountNotBlacklisted.selector, alice));

        vm.prank(blacklistManager);
        blacklistable.unblacklist(alice);
    }

    function test_unblacklist() public {
        vm.prank(blacklistManager);
        blacklistable.blacklist(alice);

        assertTrue(blacklistable.isBlacklisted(alice));

        vm.expectEmit();
        emit IBlacklistable.Unblacklisted(alice, block.timestamp);

        vm.prank(blacklistManager);
        blacklistable.unblacklist(alice);

        assertFalse(blacklistable.isBlacklisted(alice));
    }

    /* ============ unblacklistAccounts ============ */

    function test_unblacklistAccounts_onlyBlacklistManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                BLACKLIST_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        blacklistable.unblacklistAccounts(accounts);
    }

    function test_unblacklistAccounts_revertIfNotBlacklisted() public {
        address[] memory accounts = new address[](2);
        accounts[0] = alice;
        accounts[1] = bob;

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountNotBlacklisted.selector, alice));

        vm.prank(blacklistManager);
        blacklistable.unblacklistAccounts(accounts);
    }

    function test_unblacklistAccounts() public {
        vm.prank(blacklistManager);
        blacklistable.blacklistAccounts(accounts);

        for (uint256 i; i < accounts.length; ++i) {
            vm.expectEmit();
            emit IBlacklistable.Unblacklisted(accounts[i], block.timestamp);
        }

        vm.prank(blacklistManager);
        blacklistable.unblacklistAccounts(accounts);

        for (uint256 i; i < accounts.length; ++i) {
            assertFalse(blacklistable.isBlacklisted(accounts[i]));
        }
    }
}
