// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";

import {
    IAccessControl
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MYieldToOne } from "../../../src/projects/yieldToOne/MYieldToOne.sol";
import { IMYieldToOne } from "../../../src/projects/yieldToOne/IMYieldToOne.sol";

import { IFreezable } from "../../../src/components/IFreezable.sol";

import { ISwapFacility } from "../../../src/swap/interfaces/ISwapFacility.sol";

import { UsdrTokenHarness } from "../../harness/UsdrTokenHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract MYieldToOneUnitTests is BaseUnitTest {
    UsdrTokenHarness public mYieldToOne;

    string public constant NAME = "USDR testnet";
    string public constant SYMBOL = "USDR";

    function setUp() public override {
        super.setUp();

        mYieldToOne = UsdrTokenHarness(
            Upgrades.deployTransparentProxy(
                "UsdrTokenHarness.sol:UsdrTokenHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager
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

        assertTrue(IAccessControl(address(mYieldToOne)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(IAccessControl(address(mYieldToOne)).hasRole(FREEZE_MANAGER_ROLE, freezeManager));
        assertTrue(IAccessControl(address(mYieldToOne)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));
    }

    function test_initialize_zeroYieldRecipient() external {
        address implementation = address(new UsdrTokenHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipient.selector);
        UsdrTokenHarness(
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
                    yieldRecipientManager
                )
            )
        );
    }

    function test_initialize_zeroAdmin() external {
        address implementation = address(new UsdrTokenHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroAdmin.selector);
        UsdrTokenHarness(
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
                    yieldRecipientManager
                )
            )
        );
    }

    function test_initialize_zeroYieldRecipientManager() external {
        address implementation = address(new UsdrTokenHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipientManager.selector);
        UsdrTokenHarness(
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
                    address(0)
                )
            )
        );
    }

    /* ============ _approve ============ */

    function test_approve_frozenAccount() public {
        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        vm.prank(alice);
        mYieldToOne.approve(bob, 1_000e6);
    }

    function test_approve_frozenSpender() public {
        vm.prank(freezeManager);
        mYieldToOne.freeze(bob);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, bob));

        vm.prank(alice);
        mYieldToOne.approve(bob, 1_000e6);
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

        assertEq(mYieldToOne.balanceOf(alice), amount);
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

    function test_unwrap() external {
        uint256 amount = 1_000e6;

        mYieldToOne.setBalanceOf(address(swapFacility), amount);
        mYieldToOne.setBalanceOf(alice, amount);
        mYieldToOne.setTotalSupply(amount);

        mToken.setBalanceOf(address(mYieldToOne), amount);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1e6);

        vm.prank(address(swapFacility));
        mYieldToOne.unwrap(alice, 1e6);

        assertEq(mYieldToOne.totalSupply(), 999e6);
        assertEq(mYieldToOne.balanceOf(address(swapFacility)), 999e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 1e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499e6);

        vm.prank(address(swapFacility));
        mYieldToOne.unwrap(alice, 499e6);

        assertEq(mYieldToOne.totalSupply(), 500e6);
        assertEq(mYieldToOne.balanceOf(address(swapFacility)), 500e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 500e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500e6);

        vm.prank(address(swapFacility));
        mYieldToOne.unwrap(alice, 500e6);

        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(address(swapFacility)), 0);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), amount);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 0);
    }

    /* ============ _transfer ============ */
    function test_transfer_frozenSender() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        // Alice allows Carol to transfer tokens on her behalf
        vm.prank(alice);
        mYieldToOne.approve(carol, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(carol);

        // Reverts cause Carol is frozen and cannot transfer tokens on Alice's behalf
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, carol));

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, amount);
    }

    function test_transfer_frozenAccount() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));

        vm.prank(alice);
        mYieldToOne.transfer(bob, amount);
    }

    function test_transfer_frozenRecipient() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.prank(freezeManager);
        mYieldToOne.freeze(bob);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, bob));

        vm.prank(alice);
        mYieldToOne.transfer(bob, amount);
    }

    function test_transfer() external {
        uint256 amount = 1_000e6;
        mYieldToOne.setBalanceOf(alice, amount);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount);

        vm.prank(alice);
        mYieldToOne.transfer(bob, amount);

        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mYieldToOne.balanceOf(bob), amount);
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
        mYieldToOne.transfer(bob, transferAmount);

        assertEq(mYieldToOne.balanceOf(alice), aliceBalance - transferAmount);
        assertEq(mYieldToOne.balanceOf(bob), bobBalance + transferAmount);
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
        assertEq(mYieldToOne.balanceOf(yieldRecipient), yield);
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
        assertEq(mYieldToOne.balanceOf(yieldRecipient), 500);
    }
}
