// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IAccessControl } from "../../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IPausable } from "../../../../src/components/pausable/IPausable.sol";

import { PausableHarness } from "../../../harness/PausableHarness.sol";

import { BaseUnitTest } from "../../../utils/BaseUnitTest.sol";

contract PausableUnitTests is BaseUnitTest {
    PausableHarness public pausable;

    function setUp() public override {
        super.setUp();

        pausable = PausableHarness(
            Upgrades.deployTransparentProxy(
                "PausableHarness.sol:PausableHarness",
                admin,
                abi.encodeWithSelector(PausableHarness.initialize.selector, pauser)
            )
        );
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertTrue(IAccessControl(address(pausable)).hasRole(PAUSER_ROLE, pauser));
    }

    function test_initialize_zeroPauser() external {
        address implementation = address(new PausableHarness());

        vm.expectRevert(IPausable.ZeroPauser.selector);
        UnsafeUpgrades.deployTransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(PausableHarness.initialize.selector, address(0))
        );
    }

    /* ============ pause ============ */

    function test_pause_onlyPauser() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                pausable.PAUSER_ROLE()
            )
        );

        vm.prank(alice);
        pausable.pause();
    }

    function test_pause() external {
        vm.prank(pauser);
        pausable.pause();

        assertTrue(pausable.paused());
    }

    /* ============ unpause ============ */

    function test_unpause_onlyPauser() external {
        vm.prank(pauser);
        pausable.pause();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                pausable.PAUSER_ROLE()
            )
        );

        vm.prank(alice);
        pausable.unpause();
    }

    function test_unpause() external {
        vm.prank(pauser);
        pausable.pause();

        vm.prank(pauser);
        pausable.unpause();

        assertFalse(pausable.paused());
    }
}
