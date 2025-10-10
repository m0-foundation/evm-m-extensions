// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {
    IAccessControl
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {
    PausableUpgradeable
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";

import { USDZ } from "../../src/vendor/braid/USDZ.sol";

import { USDZHarness } from "../harness/USDZHarness.sol";

import { IFreezable } from "../../src/components/IFreezable.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

contract USDZIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public pauser = makeAddr("pauser");
    address public forcedTransferManager = makeAddr("forcedTransferManager");

    USDZHarness public usdz;

    function setUp() public override {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 23535885); // Block before USDZ deployment

        super.setUp();

        _fundAccounts();

        usdz = USDZHarness(
            UnsafeUpgrades.deployTransparentProxy(
                address(new USDZHarness(address(mToken), address(swapFacility))),
                admin,
                abi.encodeWithSelector(
                    USDZ.initialize.selector,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    pauser,
                    forcedTransferManager
                )
            )
        );
    }

    function test_integration_constants() external view {
        assertEq(usdz.name(), "USDZ");
        assertEq(usdz.symbol(), "USDZ");
        assertEq(usdz.decimals(), 6);
        assertEq(usdz.mToken(), address(mToken));
        assertEq(usdz.swapFacility(), address(swapFacility));
        assertEq(usdz.yieldRecipient(), yieldRecipient);

        assertTrue(IAccessControl(address(usdz)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(IAccessControl(address(usdz)).hasRole(FREEZE_MANAGER_ROLE, freezeManager));
        assertTrue(IAccessControl(address(usdz)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));
        assertTrue(IAccessControl(address(usdz)).hasRole(PAUSER_ROLE, pauser));
    }

    function test_yieldAccumulationAndClaim() external {
        uint256 amount = 10e6;

        // Enable earning for the contract
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        // Check the initial earning state
        assertEq(mToken.isEarning(address(usdz)), true);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        // Wrap from non-earner account
        _swapInM(address(usdz), alice, alice, amount);

        // Check balances of USDZ and Alice after wrapping
        assertEq(usdz.balanceOf(alice), amount); // user receives exact amount
        assertApproxEqAbs(mToken.balanceOf(address(usdz)), amount, 2); // rounds down

        // Fast forward 10 days in the future to generate yield
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // Yield accrual
        assertEq(usdz.yield(), 10498);

        // Transfers do not affect yield
        vm.prank(alice);
        usdz.transfer(bob, amount / 2);

        assertEq(usdz.balanceOf(bob), amount / 2);
        assertEq(usdz.balanceOf(alice), amount / 2);

        // Yield stays the same
        assertEq(usdz.yield(), 10498);

        // Unwraps
        _swapMOut(address(usdz), alice, alice, amount / 2);

        // Alice receives exact amount but usdz loses 1 wei
        // due to rounding up in M when transferring from an earner to a non-earner
        assertEq(usdz.yield(), 10498);

        _swapMOut(address(usdz), bob, bob, amount / 2);

        assertEq(usdz.yield(), 10498);

        assertEq(usdz.balanceOf(bob), 0);
        assertEq(usdz.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(bob), amount + amount / 2);
        assertEq(mToken.balanceOf(alice), amount / 2);

        assertEq(usdz.balanceOf(yieldRecipient), 0);

        // Claim yield
        vm.prank(yieldRecipientManager);
        usdz.claimYield();

        assertEq(usdz.balanceOf(yieldRecipient), 10498);
        assertEq(usdz.yield(), 0);
        assertEq(mToken.balanceOf(address(usdz)), 10498);
        assertEq(usdz.totalSupply(), 10498);

        // Wrap from earner account
        _addToList(EARNERS_LIST, bob);

        vm.prank(bob);
        mToken.startEarning();

        _swapInM(address(usdz), bob, bob, amount);

        // Check balances of USDZ and Bob after wrapping
        assertEq(usdz.balanceOf(bob), amount);
        assertEq(mToken.balanceOf(address(usdz)), 10498 + amount - 1); // Rounds down since USDZ is earning

        // Disable earning for the contract
        _removeFromList(EARNERS_LIST, address(usdz));
        usdz.disableEarning();

        assertFalse(usdz.isEarningEnabled());

        // Fast forward 10 days in the future
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // No yield should accrue
        assertEq(usdz.yield(), 0);

        // Re-enable earning for the contract
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        // Yield should accrue again
        vm.warp(vm.getBlockTimestamp() + 10 days);

        assertEq(usdz.yield(), 10508);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_notApprovedEarner() external {
        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.NotApprovedEarner.selector));
        usdz.enableEarning();
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_approvedEarner() external {
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.IsApprovedEarner.selector));
        usdz.disableEarning();
    }

    /* ============ wrap ============ */

    function test_wrap() external {
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        assertEq(mToken.balanceOf(alice), 10e6);

        _swapInM(address(usdz), alice, alice, 5e6);

        assertEq(usdz.balanceOf(alice), 5e6);
        assertEq(usdz.totalSupply(), 5e6);

        assertEq(mToken.balanceOf(alice), 5e6);
        assertApproxEqAbs(mToken.balanceOf(address(usdz)), 5e6, 1);

        assertEq(usdz.yield(), 0);

        _swapInM(address(usdz), alice, alice, 5e6);

        assertEq(usdz.balanceOf(alice), 10e6);
        assertEq(usdz.totalSupply(), 10e6);

        assertEq(mToken.balanceOf(alice), 0);
        assertApproxEqAbs(mToken.balanceOf(address(usdz)), 10e6, 2);

        assertEq(usdz.yield(), 0);

        // Move time forward to generate yield
        vm.warp(vm.getBlockTimestamp() + 365 days);

        assertEq(usdz.yield(), 390428);

        assertEq(usdz.balanceOf(alice), 10e6);
        assertEq(usdz.totalSupply(), 10e6);
    }

    function test_wrapWithPermits() external {
        _addToList(EARNERS_LIST, address(usdz));

        assertEq(mToken.balanceOf(alice), 10e6);

        _swapInMWithPermitVRS(address(usdz), alice, aliceKey, alice, 5e6, 0, block.timestamp);

        assertEq(usdz.balanceOf(alice), 5e6);
        assertEq(mToken.balanceOf(alice), 5e6);

        _swapInMWithPermitSignature(address(usdz), alice, aliceKey, alice, 5e6, 1, block.timestamp);

        assertEq(usdz.balanceOf(alice), 10e6);
        assertEq(mToken.balanceOf(alice), 0);
    }

    /* ============ unwrap ============ */

    function test_unwrap() external {
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        usdz.setBalanceOf(alice, 10e6);
        usdz.setTotalSupply(10e6);
        _giveM(address(usdz), 10e6);

        // 2 wei are lost due to rounding
        assertApproxEqAbs(mToken.balanceOf(address(usdz)), 10e6, 2);
        assertEq(mToken.balanceOf(alice), 10e6);
        assertEq(usdz.balanceOf(alice), 10e6);
        assertEq(usdz.totalSupply(), 10e6);

        // Move time forward to generate yield
        vm.warp(vm.getBlockTimestamp() + 365 days);

        assertEq(usdz.yield(), 390429);

        _swapMOut(address(usdz), alice, alice, 5e6);

        assertApproxEqAbs(mToken.balanceOf(address(usdz)), 390429 + 5e6, 1);
        assertEq(mToken.balanceOf(alice), 15e6);
        assertEq(usdz.balanceOf(alice), 5e6);
        assertEq(usdz.totalSupply(), 5e6);

        _swapMOut(address(usdz), alice, alice, 5e6);

        assertEq(mToken.balanceOf(alice), 20e6);

        // Alice's full withdrawal would have reverted without yield.
        // The 1 wei lost due to rounding were covered by the yield.
        assertEq(usdz.yield(), 390429 - 1);
        assertEq(mToken.balanceOf(address(usdz)), 390429 - 1);

        assertEq(usdz.balanceOf(alice), 0);
        assertEq(usdz.totalSupply(), 0);
    }

    function test_unwrapWithPermits() external {
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        usdz.setBalanceOf(alice, 11e6);
        usdz.setTotalSupply(11e6);
        _giveM(address(usdz), 11e6);

        assertEq(mToken.balanceOf(alice), 10e6);
        assertEq(usdz.balanceOf(alice), 11e6);

        _swapOutMWithPermitVRS(address(usdz), alice, aliceKey, alice, 5e6, 0, block.timestamp);

        assertEq(usdz.balanceOf(alice), 6e6);
        assertEq(mToken.balanceOf(alice), 15e6);

        _swapOutMWithPermitSignature(address(usdz), alice, aliceKey, alice, 5e6, 1, block.timestamp);

        assertEq(usdz.balanceOf(alice), 1e6);
        assertEq(mToken.balanceOf(alice), 20e6);
    }

    /* ============ claimYield ============ */

    function test_claimYield() external {
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        usdz.setBalanceOf(alice, 10e6);
        usdz.setTotalSupply(10e6);
        _giveM(address(usdz), 10e6);

        // 2 wei are lost due to rounding
        assertApproxEqAbs(mToken.balanceOf(address(usdz)), 10e6, 2);
        assertEq(usdz.balanceOf(yieldRecipient), 0);

        // Move time forward to generate yield
        vm.warp(vm.getBlockTimestamp() + 365 days);

        assertEq(usdz.yield(), 390429);
        assertEq(usdz.totalSupply(), 10e6);
        assertEq(mToken.balanceOf(address(usdz)), 10e6 + 390429); // Rounding error has been covered by yield

        vm.prank(yieldRecipientManager);
        assertEq(usdz.claimYield(), 390429);

        assertEq(usdz.yield(), 0);
        assertEq(usdz.totalSupply(), 10e6 + 390429);
        assertEq(usdz.balanceOf(yieldRecipient), 390429);
        assertEq(mToken.balanceOf(address(usdz)), 10e6 + 390429);
    }

    /* ============ pause ============ */

    function test_whenPaused() external {
        uint256 amount = 1e6;

        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        usdz.setBalanceOf(alice, amount);
        usdz.setTotalSupply(amount);

        _giveM(address(usdz), amount);

        vm.prank(alice);
        usdz.approve(address(swapFacility), amount);

        vm.prank(pauser);
        usdz.pause();

        bytes4 selector = PausableUpgradeable.EnforcedPause.selector;

        // test wrap
        vm.prank(alice);
        mToken.approve(address(swapFacility), amount);

        vm.expectRevert(selector);

        vm.prank(alice);
        swapFacility.swapInM(address(usdz), amount, alice);

        // test unwrap
        vm.prank(alice);

        // Approval should not revert when contract is paused
        usdz.approve(address(swapFacility), amount);

        vm.expectRevert(selector);

        vm.prank(alice);
        swapFacility.swapOutM(address(usdz), amount, alice);

        vm.expectRevert(selector);

        vm.prank(alice);
        usdz.transfer(bob, amount);

        // claimYield is not paused
        vm.warp(block.timestamp + 1 days);

        uint256 yield = usdz.yield();
        assertGt(yield, 0);

        vm.prank(yieldRecipientManager);
        usdz.claimYield();

        assertEq(usdz.balanceOf(yieldRecipient), yield);
    }

    function test_freezeManagers() external {
        uint256 amount = 10e6;

        /*********** SETUP ************/

        // Enable earning for the contract
        _addToList(EARNERS_LIST, address(usdz));
        usdz.enableEarning();

        // Check initial earning state
        assertEq(mToken.isEarning(address(usdz)), true);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        _swapInM(address(usdz), alice, alice, amount);

        assertEq(usdz.balanceOf(alice), amount);
        assertApproxEqAbs(mToken.balanceOf(address(usdz)), amount, 2);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        assertEq(usdz.yield(), 10498);

        /*********** DONE SETUP ************/

        vm.prank(freezeManager);
        usdz.freeze(alice);

        assertTrue(usdz.isFrozen(alice));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        usdz.transfer(bob, amount);

        vm.prank(freezeManager);
        usdz.unfreeze(alice);

        assertFalse(usdz.isFrozen(alice));

        vm.prank(alice);
        usdz.transfer(bob, amount);

        assertEq(usdz.balanceOf(alice), 0);
        assertEq(usdz.balanceOf(bob), amount);

        vm.prank(freezeManager);
        usdz.freeze(bob);

        assertTrue(usdz.isFrozen(bob));

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, bob));
        usdz.approve(alice, amount);

        vm.prank(freezeManager);
        usdz.unfreeze(bob);

        assertFalse(usdz.isFrozen(bob));

        vm.prank(bob);
        usdz.approve(alice, amount);

        assertEq(usdz.allowance(bob, alice), amount);

        vm.prank(freezeManager);
        usdz.freeze(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        usdz.transferFrom(bob, alice, amount);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        usdz.transfer(alice, amount);

        vm.prank(freezeManager);
        usdz.unfreeze(alice);

        vm.prank(alice);
        usdz.transferFrom(bob, alice, amount);

        assertEq(usdz.balanceOf(alice), amount);
        assertEq(usdz.balanceOf(bob), 0);

        address freezeManager2 = makeAddr("freezeManager2");

        bytes32 freezeManagerRole = usdz.FREEZE_MANAGER_ROLE();

        vm.prank(admin);
        usdz.grantRole(freezeManagerRole, freezeManager2);

        vm.prank(freezeManager2);
        usdz.freeze(bob);

        assertTrue(usdz.isFrozen(bob));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, bob));
        usdz.transfer(bob, amount);
    }
}
