// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.26;

import { IERC20 } from "../../../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../../../lib/common/src/interfaces/IERC20Extended.sol";

import { IAccessControl } from "../../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import { PausableUpgradeable } from "../../../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { Upgrades, UnsafeUpgrades } from "../../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MYieldToOne } from "../../../../src/projects/yieldToOne/MYieldToOne.sol";
import { IMYieldToOne } from "../../../../src/projects/yieldToOne/interfaces/IMYieldToOne.sol";
import { IMExtension } from "../../../../src/interfaces/IMExtension.sol";

import { IFreezable } from "../../../../src/components/freezable/IFreezable.sol";
import { IPausable } from "../../../../src/components/pausable/IPausable.sol";

import { ISwapFacility } from "../../../../src/swap/interfaces/ISwapFacility.sol";

import { MYieldToOneHarness } from "../../../harness/MYieldToOneHarness.sol";

import { BaseUnitTest } from "../../../utils/BaseUnitTest.sol";

contract MYieldToOneUnitTests is BaseUnitTest {
    MYieldToOneHarness public mYieldToOne;

    string public constant NAME = "HALO USD";
    string public constant SYMBOL = "HALO USD";

    function setUp() public override {
        super.setUp();

        mYieldToOne = MYieldToOneHarness(
            Upgrades.deployTransparentProxy(
                "MYieldToOneHarness.sol:MYieldToOneHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    pauser
                ),
                mExtensionDeployOptions
            )
        );

        registrar.setEarner(address(mYieldToOne), true);
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertEq(mYieldToOne.name(), NAME);
        assertEq(mYieldToOne.symbol(), SYMBOL);
        assertEq(mYieldToOne.decimals(), 6);
        assertEq(mYieldToOne.mToken(), address(mToken));
        assertEq(mYieldToOne.swapFacility(), address(swapFacility));
        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);

        assertTrue(mYieldToOne.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mYieldToOne.hasRole(FREEZE_MANAGER_ROLE, freezeManager));
        assertTrue(mYieldToOne.hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));
        assertTrue(mYieldToOne.hasRole(PAUSER_ROLE, pauser));
    }

    function test_initialize_zeroYieldRecipient() external {
        address implementation = address(new MYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipient.selector);
        MYieldToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(0),
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    pauser
                )
            )
        );
    }

    function test_initialize_zeroAdmin() external {
        address implementation = address(new MYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroAdmin.selector);
        MYieldToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(yieldRecipient),
                    address(0),
                    freezeManager,
                    yieldRecipientManager,
                    pauser
                )
            )
        );
    }

    function test_initialize_zeroYieldRecipientManager() external {
        address implementation = address(new MYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipientManager.selector);
        MYieldToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(yieldRecipient),
                    admin,
                    freezeManager,
                    address(0),
                    pauser
                )
            )
        );
    }

    function test_initialize_zeroPauser() external {
        address implementation = address(new MYieldToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IPausable.ZeroPauser.selector);
        mYieldToOne = MYieldToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager,
                    address(0)
                )
            )
        );
    }

    /* ============ approve (shielded) ============ */

    function test_approve_frozenAccount() public {
        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        vm.prank(alice);
        mYieldToOne.approve(bob, suint256(1_000e6));
    }

    function test_approve_frozenSpender() public {
        vm.prank(freezeManager);
        mYieldToOne.freeze(bob);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, bob));

        vm.prank(alice);
        mYieldToOne.approve(bob, suint256(1_000e6));
    }

    function test_approve_writesShieldedStorage() public {
        uint256 amount = 1_000e6;

        vm.expectEmit();
        emit IERC20.Approval(alice, bob, amount);

        vm.prank(alice);
        mYieldToOne.approve(bob, suint256(amount));

        assertEq(mYieldToOne.getShieldedAllowance(alice, bob), amount);
    }

    function test_approve_inheritedPathReverts() public {
        // The IERC20 `approve(address,uint256)` is overridden to revert at the entry point.
        vm.expectRevert(IMYieldToOne.UseShieldedApprove.selector);

        vm.prank(alice);
        mYieldToOne.approve(bob, 1_000e6);
    }

    function test_approve_permitReverts() public {
        // Inherited EIP-2612 `permit` is overridden to revert directly at the entry point —
        // both the v/r/s overload and the bytes-signature overload.
        vm.expectRevert(IMYieldToOne.UseShieldedApprove.selector);
        mYieldToOne.permit(alice, bob, 1_000e6, type(uint256).max, 0, bytes32(0), bytes32(0));

        vm.expectRevert(IMYieldToOne.UseShieldedApprove.selector);
        mYieldToOne.permit(alice, bob, 1_000e6, type(uint256).max, "");
    }

    /* ============ balanceOf (gated read) ============ */

    function test_balanceOf_holderCanRead() public {
        mYieldToOne.setBalanceOf(alice, 1_000e6);

        vm.prank(alice);
        assertEq(mYieldToOne.balanceOf(alice), 1_000e6);
    }

    function test_balanceOf_unauthorized() public {
        mYieldToOne.setBalanceOf(alice, 1_000e6);

        vm.expectRevert(IMYieldToOne.Unauthorized.selector);
        vm.prank(bob);
        mYieldToOne.balanceOf(alice);
    }

    function test_balanceOf_swapFacilityCanRead() public {
        mYieldToOne.setBalanceOf(alice, 1_000e6);

        // SwapFacility is exempted so M0 infra can observe extension balances along its
        // operational paths without forcing a Seismic signed read.
        vm.prank(address(swapFacility));
        assertEq(mYieldToOne.balanceOf(alice), 1_000e6);
    }

    /* ============ allowance (gated read) ============ */

    function test_allowance_unauthorized() public {
        // alice approves bob; carol (third party) attempts to read → reverts.
        vm.prank(alice);
        mYieldToOne.approve(bob, suint256(500e6));

        vm.expectRevert(IMYieldToOne.Unauthorized.selector);
        vm.prank(carol);
        mYieldToOne.allowance(alice, bob);
    }

    function test_allowance_ownerCanRead() public {
        vm.prank(alice);
        mYieldToOne.approve(bob, suint256(500e6));

        vm.prank(alice);
        assertEq(mYieldToOne.allowance(alice, bob), 500e6);
    }

    function test_allowance_spenderCanRead() public {
        vm.prank(alice);
        mYieldToOne.approve(bob, suint256(500e6));

        vm.prank(bob);
        assertEq(mYieldToOne.allowance(alice, bob), 500e6);
    }

    /* ============ _wrap ============ */

    function test_wrap_frozenAccount() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.mockCall(address(swapFacility), abi.encodeWithSelector(ISwapFacility.msgSender.selector), abi.encode(alice));

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        vm.prank(address(swapFacility));
        mYieldToOne.wrap(bob, amount);
    }

    function test_wrap_frozenRecipient() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(bob);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, bob));

        vm.prank(address(swapFacility));
        mYieldToOne.wrap(bob, amount);
    }

    function test_wrap_paused() public {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(address(swapFacility), amount);

        vm.prank(pauser);
        mYieldToOne.pause();

        vm.mockCall(address(swapFacility), abi.encodeWithSelector(swapFacility.msgSender.selector), abi.encode(bob));

        vm.prank(address(swapFacility));
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        mYieldToOne.wrap(bob, 1);
    }

    function test_wrap() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(address(swapFacility), amount);

        vm.expectCall(
            address(mToken),
            abi.encodeWithSelector(mToken.transferFrom.selector, address(swapFacility), address(mYieldToOne), amount)
        );

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, amount);

        vm.prank(address(swapFacility));
        mYieldToOne.wrap(alice, amount);

        assertEq(mYieldToOne.getBalanceOf(alice), amount);
        assertEq(mYieldToOne.totalSupply(), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mYieldToOne)), amount);
    }

    /* ============ _unwrap ============ */
    function test_unwrap_frozenAccount() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.mockCall(address(swapFacility), abi.encodeWithSelector(ISwapFacility.msgSender.selector), abi.encode(alice));

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        vm.prank(address(swapFacility));
        mYieldToOne.unwrap(alice, amount);
    }

    function test_unwrap_paused() public {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(address(swapFacility), amount);

        vm.prank(pauser);
        mYieldToOne.pause();

        vm.mockCall(address(swapFacility), abi.encodeWithSelector(swapFacility.msgSender.selector), abi.encode(alice));

        vm.prank(address(swapFacility));
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        mYieldToOne.unwrap(alice, 1);
    }

    function test_unwrap() external {
        uint256 amount = 1_000e6;

        mYieldToOne.setBalanceOf(address(swapFacility), amount);
        mYieldToOne.setTotalSupply(amount);

        mToken.setBalanceOf(address(mYieldToOne), amount);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1e6);

        vm.prank(address(swapFacility));
        mYieldToOne.unwrap(alice, 1e6);

        assertEq(mYieldToOne.totalSupply(), 999e6);
        assertEq(mYieldToOne.getBalanceOf(address(swapFacility)), 999e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 1e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499e6);

        vm.prank(address(swapFacility));
        mYieldToOne.unwrap(alice, 499e6);

        assertEq(mYieldToOne.totalSupply(), 500e6);
        assertEq(mYieldToOne.getBalanceOf(address(swapFacility)), 500e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 500e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500e6);

        vm.prank(address(swapFacility));
        mYieldToOne.unwrap(alice, 500e6);

        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.getBalanceOf(address(swapFacility)), 0);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), amount);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 0);
    }

    /* ============ transfer (shielded) ============ */
    function test_transfer_frozenSpender() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        // Alice allows Carol to transfer tokens on her behalf (shielded approve).
        vm.prank(alice);
        mYieldToOne.approve(carol, suint256(amount));

        vm.prank(freezeManager);
        mYieldToOne.freeze(carol);

        // Reverts because Carol (the spender / msg.sender) is frozen.
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, carol));

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, suint256(amount));
    }

    function test_transfer_frozenAccount() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        vm.prank(alice);
        mYieldToOne.transfer(bob, suint256(amount));
    }

    function test_transfer_frozenRecipient() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(bob);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, bob));

        vm.prank(alice);
        mYieldToOne.transfer(bob, suint256(amount));
    }

    function test_transfer_paused() public {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(pauser);
        mYieldToOne.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(alice);
        mYieldToOne.transfer(bob, suint256(1));
    }

    function test_transfer() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount);

        vm.prank(alice);
        mYieldToOne.transfer(bob, suint256(amount));

        assertEq(mYieldToOne.getBalanceOf(alice), 0);
        assertEq(mYieldToOne.getBalanceOf(bob), amount);
    }

    function test_transfer_insufficientBalance() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount - 1);

        // Shielded comparison reverts with `balance = 0` (not the real balance) to avoid leak.
        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 0, amount));

        vm.prank(alice);
        mYieldToOne.transfer(bob, suint256(amount));
    }

    function test_transfer_inheritedPathReverts() external {
        // The IERC20 `transfer(address,uint256)` is overridden to revert at the entry point —
        // no balance / freeze / pause state matters.
        vm.expectRevert(IMYieldToOne.UseShieldedTransfer.selector);

        vm.prank(alice);
        mYieldToOne.transfer(bob, 1_000e6);
    }

    function testFuzz_transfer(uint256 supply, uint256 aliceBalance, uint256 transferAmount) external {
        supply = bound(supply, 1, type(uint240).max);
        aliceBalance = bound(aliceBalance, 1, supply);
        transferAmount = bound(transferAmount, 1, aliceBalance);
        uint256 bobBalance = supply - aliceBalance;

        if (bobBalance == 0) return;

        mYieldToOne.setBalanceOf(alice, aliceBalance);
        mYieldToOne.setBalanceOf(bob, bobBalance);

        vm.prank(alice);
        mYieldToOne.transfer(bob, suint256(transferAmount));

        assertEq(mYieldToOne.getBalanceOf(alice), aliceBalance - transferAmount);
        assertEq(mYieldToOne.getBalanceOf(bob), bobBalance + transferAmount);
    }

    /* ============ transferFrom (shielded) ============ */

    function test_transferFrom_finiteAllowanceDecrements() external {
        uint256 amount = 1_000e6;
        uint256 allowanceAmount = 1_500e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.approve(carol, suint256(allowanceAmount));

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount);

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, suint256(amount));

        assertEq(mYieldToOne.getBalanceOf(alice), 0);
        assertEq(mYieldToOne.getBalanceOf(bob), amount);
        assertEq(mYieldToOne.getShieldedAllowance(alice, carol), allowanceAmount - amount);
    }

    function test_transferFrom_infiniteAllowanceNoDecrement() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.approve(carol, suint256(type(uint256).max));

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, suint256(amount));

        // Infinite allowance is preserved (matches ERC20ExtendedUpgradeable.transferFrom semantics).
        assertEq(mYieldToOne.getShieldedAllowance(alice, carol), type(uint256).max);
    }

    function test_transferFrom_insufficientAllowance() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.approve(carol, suint256(amount - 1));

        // Allowance field zeroed in the revert payload — matches the shielded-balance precedent.
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAllowance.selector, carol, 0, amount));

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, suint256(amount));
    }

    function test_transferFrom_noAllowance() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        // No prior approve — shielded allowance is zero.
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAllowance.selector, carol, 0, amount));

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, suint256(amount));
    }

    function test_transferFrom_inheritedPathReverts() external {
        // The IERC20 `transferFrom(address,address,uint256)` is overridden to revert at the
        // entry point.
        vm.expectRevert(IMYieldToOne.UseShieldedTransfer.selector);

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, 1_000e6);
    }

    /* ============ yield ============ */
    function test_yield() external {
        assertEq(mYieldToOne.yield(), 0);

        mToken.setBalanceOf(address(mYieldToOne), 1_500e6);
        mYieldToOne.setTotalSupply(1_000e6);

        assertEq(mYieldToOne.yield(), 500e6);
    }

    function testFuzz_yield(uint256 mBalance, uint256 totalSupply) external {
        mBalance = bound(mBalance, 0, type(uint240).max);
        totalSupply = bound(totalSupply, 0, mBalance);

        mToken.setBalanceOf(address(mYieldToOne), mBalance);
        mYieldToOne.setTotalSupply(totalSupply);

        assertEq(mYieldToOne.yield(), mBalance - totalSupply);
    }

    /* ============ claimYield ============ */
    function test_claimYield_noYield() external {
        vm.prank(alice);
        uint256 yield = mYieldToOne.claimYield();

        assertEq(yield, 0);
    }

    function test_claimYield() external {
        uint256 yield = 500e6;

        mToken.setBalanceOf(address(mYieldToOne), 1_500e6);
        mYieldToOne.setTotalSupply(1_000e6);

        assertEq(mYieldToOne.yield(), yield);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(yield);

        assertEq(mYieldToOne.claimYield(), yield);

        assertEq(mYieldToOne.yield(), 0);

        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_500e6);
        assertEq(mYieldToOne.totalSupply(), 1_500e6);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mYieldToOne.getBalanceOf(yieldRecipient), yield);
    }

    /* ============ setYieldRecipient ============ */

    function test_setYieldRecipient_onlyYieldRecipientManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                YIELD_RECIPIENT_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        mYieldToOne.setYieldRecipient(alice);
    }

    function test_setYieldRecipient_zeroYieldRecipient() public {
        vm.expectRevert(IMYieldToOne.ZeroYieldRecipient.selector);

        vm.prank(yieldRecipientManager);
        mYieldToOne.setYieldRecipient(address(0));
    }

    function test_setYieldRecipient_noUpdate() public {
        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);

        vm.prank(yieldRecipientManager);
        mYieldToOne.setYieldRecipient(yieldRecipient);

        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);
    }

    function test_setYieldRecipient() public {
        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);

        vm.expectEmit();
        emit IMYieldToOne.YieldRecipientSet(alice);

        vm.prank(yieldRecipientManager);
        mYieldToOne.setYieldRecipient(alice);

        assertEq(mYieldToOne.yieldRecipient(), alice);
    }

    function test_setYieldRecipient_claimYield() public {
        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);

        mToken.setBalanceOf(address(mYieldToOne), mYieldToOne.totalSupply() + 500);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(500);

        vm.prank(yieldRecipientManager);
        mYieldToOne.setYieldRecipient(alice);

        assertEq(mYieldToOne.yieldRecipient(), alice);
        assertEq(mYieldToOne.yield(), 0);
        assertEq(mYieldToOne.getBalanceOf(yieldRecipient), 500);
    }
}
