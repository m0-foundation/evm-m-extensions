// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import {
    IAccessControl
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MockM } from "../utils/Mocks.sol";

import { MYieldToOne } from "../../src/MYieldToOne.sol";

import { IBlacklistable } from "../../src/interfaces/IBlacklistable.sol";
import { IMYieldToOne } from "../../src/interfaces/IMYieldToOne.sol";
import { IMExtension } from "../../src/interfaces/IMExtension.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../lib/common/src/interfaces/IERC20Extended.sol";

import { BaseUnitTest } from "../utils/BaseUnitTest.sol";

contract MYieldToOneUnitTests is BaseUnitTest {
    // Roles
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant YIELD_RECIPIENT_MANAGER_ROLE = keccak256("YIELD_RECIPIENT_MANAGER_ROLE");

    MYieldToOne public mYieldToOne;

    string public constant NAME = "HALO USD";
    string public constant SYMBOL = "HALO USD";

    function setUp() public override {
        super.setUp();

        mToken = new MockM();

        mYieldToOne = MYieldToOne(
            Upgrades.deployUUPSProxy(
                "MYieldToOne.sol:MYieldToOne",
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(mToken),
                    yieldRecipient,
                    admin,
                    blacklistManager,
                    yieldRecipientManager
                )
            )
        );
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertEq(mYieldToOne.name(), NAME);
        assertEq(mYieldToOne.symbol(), SYMBOL);
        assertEq(mYieldToOne.decimals(), 6);
        assertEq(mYieldToOne.mToken(), address(mToken));
        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);

        assertTrue(IAccessControl(address(mYieldToOne)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(IAccessControl(address(mYieldToOne)).hasRole(BLACKLIST_MANAGER_ROLE, blacklistManager));
        assertTrue(IAccessControl(address(mYieldToOne)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));
    }

    function test_initialize_zeroMToken() external {
        address implementation = address(new MYieldToOne());

        vm.expectRevert(IMExtension.ZeroMToken.selector);
        MYieldToOne(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(0),
                    address(yieldRecipient),
                    admin,
                    blacklistManager,
                    yieldRecipientManager
                )
            )
        );
    }

    function test_initialize_zeroYieldRecipient() external {
        address implementation = address(new MYieldToOne());

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipient.selector);
        MYieldToOne(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(mToken),
                    address(0),
                    admin,
                    blacklistManager,
                    yieldRecipientManager
                )
            )
        );
    }

    function test_initialize_zeroDefaultAdmin() external {
        address implementation = address(new MYieldToOne());

        vm.expectRevert(IMYieldToOne.ZeroDefaultAdmin.selector);
        MYieldToOne(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(mToken),
                    address(yieldRecipient),
                    address(0),
                    blacklistManager,
                    yieldRecipientManager
                )
            )
        );
    }

    function test_initialize_zeroBlacklistManager() external {
        address implementation = address(new MYieldToOne());

        vm.expectRevert(IBlacklistable.ZeroBlacklistManager.selector);
        MYieldToOne(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(mToken),
                    address(yieldRecipient),
                    admin,
                    address(0),
                    yieldRecipientManager
                )
            )
        );
    }

    function test_initialize_zeroYieldRecipientManager() external {
        address implementation = address(new MYieldToOne());

        vm.expectRevert(IMYieldToOne.ZeroYieldRecipientManager.selector);
        MYieldToOne(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(mToken),
                    address(yieldRecipient),
                    admin,
                    blacklistManager,
                    address(0)
                )
            )
        );
    }

    /* ============ _approve ============ */

    function test_approve_blacklistedAccount() public {
        vm.prank(blacklistManager);
        mYieldToOne.blacklist(alice);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, alice));

        vm.prank(alice);
        mYieldToOne.approve(bob, 1_000e6);
    }

    function test_approve_blacklistedSpender() public {
        vm.prank(blacklistManager);
        mYieldToOne.blacklist(bob);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, bob));

        vm.prank(alice);
        mYieldToOne.approve(bob, 1_000e6);
    }

    /* ============ _wrap ============ */

    function test_wrap_blacklistedAccount() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(alice);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, alice));

        vm.prank(alice);
        mYieldToOne.wrap(bob, amount);
    }

    function test_wrap_blacklistedRecipient() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(bob);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, bob));

        vm.prank(alice);
        mYieldToOne.wrap(bob, amount);
    }

    function test_wrap_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(alice);
        mYieldToOne.wrap(alice, 0);
    }

    function test_wrap_invalidRecipient() external {
        mToken.setBalanceOf(alice, 1_000);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(alice);
        mYieldToOne.wrap(address(0), 1_000);
    }

    function test_wrap() external {
        mToken.setBalanceOf(alice, 2_000);

        assertEq(mToken.balanceOf(alice), 2_000);
        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mYieldToOne.yield(), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(alice, 1_000);

        assertEq(mToken.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_000);
        assertEq(mYieldToOne.yield(), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), bob, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(bob, 1_000);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.totalSupply(), 2_000);
        assertEq(mYieldToOne.balanceOf(bob), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 2_000);
        assertEq(mYieldToOne.yield(), 0);

        // simulate yield accrual by increasing accrued
        mToken.setBalanceOf(address(mYieldToOne), 2_500);
        assertEq(mYieldToOne.yield(), 500);
        assertEq(mYieldToOne.balanceOf(bob), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
    }

    /* ============ wrapWithPermit vrs ============ */

    function test_wrapWithPermit_vrs() external {
        mToken.setBalanceOf(alice, 1_000);

        assertEq(mToken.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1_000);

        vm.startPrank(alice);
        mYieldToOne.wrapWithPermit(alice, 1_000, 0, 0, bytes32(0), bytes32(0));

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.totalSupply(), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_000);
    }

    /* ============ wrapWithPermit signature ============ */
    function test_wrapWithPermit_signature() external {
        mToken.setBalanceOf(alice, 1_000);

        assertEq(mToken.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 0);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1_000);

        vm.startPrank(alice);
        mYieldToOne.wrapWithPermit(alice, 1_000, 0, hex"");

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.totalSupply(), 1_000);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_000);
    }

    /* ============ _unwrap ============ */
    function test_unwrap_blacklistedAccount() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(alice);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, alice));

        vm.prank(alice);
        mYieldToOne.unwrap(bob, amount);
    }

    function test_unwrap_blacklistedRecipient() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(bob);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, bob));

        vm.prank(alice);
        mYieldToOne.unwrap(bob, amount);
    }

    function test_unwrap_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 0);
    }

    function test_unwrap_insufficientBalance() external {
        mToken.setBalanceOf(alice, 999);
        vm.prank(alice);
        mYieldToOne.wrap(alice, 999);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 1_000);
    }

    function test_unwrap() external {
        mToken.setBalanceOf(alice, 1000);
        vm.prank(alice);
        mYieldToOne.wrap(alice, 1000);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mYieldToOne.balanceOf(alice), 1_000);
        assertEq(mYieldToOne.totalSupply(), 1_000);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 1);

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 1);

        assertEq(mYieldToOne.totalSupply(), 999);
        assertEq(mYieldToOne.balanceOf(alice), 999);
        assertEq(mToken.balanceOf(alice), 1);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 499);

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 499);

        assertEq(mYieldToOne.totalSupply(), 500);
        assertEq(mYieldToOne.balanceOf(alice), 500);
        assertEq(mToken.balanceOf(alice), 500);

        vm.expectEmit();
        emit IERC20.Transfer(alice, address(0), 500);

        vm.prank(alice);
        mYieldToOne.unwrap(alice, 500);

        assertEq(mYieldToOne.totalSupply(), 0);
        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(alice), 1000);
    }

    /* ============ _transfer ============ */
    function test_transfer_insufficientBalance() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, amount, amount + 1));

        vm.prank(alice);
        mYieldToOne.transfer(bob, amount + 1);
    }

    function test_transfer_blacklistedSender() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        // Alice allows Carol to transfer tokens on her behalf
        vm.prank(alice);
        mYieldToOne.approve(carol, amount);

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(carol);

        // Reverts cause Carol is blacklisted and cannot transfer tokens on Alice's behalf
        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, carol));

        vm.prank(carol);
        mYieldToOne.transferFrom(alice, bob, amount);
    }

    function test_transfer_blacklistedAccount() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(alice);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, alice));

        vm.prank(alice);
        mYieldToOne.transfer(bob, amount);
    }

    function test_transfer_blacklistedRecipient() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        vm.prank(blacklistManager);
        mYieldToOne.blacklist(bob);

        vm.expectRevert(abi.encodeWithSelector(IBlacklistable.AccountBlacklisted.selector, bob));

        vm.prank(alice);
        mYieldToOne.transfer(bob, amount);
    }

    function test_transfer_invalidRecipient() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, 0));

        vm.prank(alice);
        mYieldToOne.transfer(address(0), amount);
    }

    function test_transfer() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(alice, amount);

        vm.prank(alice);
        mYieldToOne.wrap(alice, amount);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount);

        vm.prank(alice);
        mYieldToOne.transfer(bob, amount);

        assertEq(mYieldToOne.balanceOf(alice), 0);
        assertEq(mYieldToOne.balanceOf(bob), amount);
    }

    function testFuzz_transfer(uint256 supply, uint256 aliceBalance, uint256 transferAmount) external {
        supply = bound(supply, 1, type(uint112).max);
        aliceBalance = bound(aliceBalance, 1, supply);
        transferAmount = bound(transferAmount, 1, aliceBalance);
        uint256 bobBalance = supply - aliceBalance;

        if (bobBalance == 0) return;

        mToken.setBalanceOf(alice, aliceBalance);
        mToken.setBalanceOf(bob, bobBalance);

        vm.prank(alice);
        mYieldToOne.wrap(alice, aliceBalance);

        if (bobBalance > 0) {
            vm.prank(bob);
            mYieldToOne.wrap(bob, bobBalance);
        }

        vm.prank(alice);
        mYieldToOne.transfer(bob, transferAmount);

        assertEq(mYieldToOne.balanceOf(alice), aliceBalance - transferAmount);
        assertEq(mYieldToOne.balanceOf(bob), bobBalance + transferAmount);
    }

    /* ============ yield ============ */
    function test_yield() external {
        mToken.setBalanceOf(alice, 1_000);
        mToken.setBalanceOf(bob, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(alice, 1_000);

        vm.prank(bob);
        mYieldToOne.wrap(bob, 1_000);

        assertEq(mYieldToOne.yield(), 0);

        mToken.setBalanceOf(address(mYieldToOne), mYieldToOne.totalSupply() + 500);

        assertEq(mYieldToOne.yield(), 500);
    }

    /* ============ claimYield ============ */
    function test_claimYield_noYield() external {
        vm.expectRevert(IMYieldToOne.NoYield.selector);

        vm.prank(alice);
        mYieldToOne.claimYield();
    }

    function test_claimYield() external {
        mToken.setBalanceOf(alice, 1_000);

        vm.prank(alice);
        mYieldToOne.wrap(alice, 1_000);

        mToken.setBalanceOf(address(mYieldToOne), mYieldToOne.totalSupply() + 500);

        assertEq(mYieldToOne.yield(), 500);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(500);

        mYieldToOne.claimYield();

        assertEq(mYieldToOne.yield(), 0);

        assertEq(mToken.balanceOf(address(mYieldToOne)), mYieldToOne.totalSupply());
        assertEq(mToken.balanceOf(address(mYieldToOne)), 1_500);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mYieldToOne.balanceOf(yieldRecipient), 500);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_earningEnabled() external {
        mYieldToOne.enableEarning();

        vm.expectRevert(IMExtension.EarningIsEnabled.selector);
        mYieldToOne.enableEarning();
    }

    function test_enableEarning() external {
        mToken.setCurrentIndex(1_210000000000);

        vm.expectEmit();
        emit IMExtension.EarningEnabled(1_210000000000);

        mYieldToOne.enableEarning();

        assertEq(mYieldToOne.isEarningEnabled(), true);
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_earningIsDisabled() external {
        vm.expectRevert(IMExtension.EarningIsDisabled.selector);
        mYieldToOne.disableEarning();
    }

    function test_disableEarning() external {
        mToken.setCurrentIndex(1_100000000000);

        mYieldToOne.enableEarning();

        mToken.setCurrentIndex(1_200000000000);

        mYieldToOne.disableEarning();

        assertEq(mYieldToOne.isEarningEnabled(), false);
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
}
