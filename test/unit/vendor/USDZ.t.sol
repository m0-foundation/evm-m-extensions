// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {
    IAccessControl
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import {
    PausableUpgradeable
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { IERC20 } from "../../../lib/forge-std/src/interfaces/IERC20.sol";

import { UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IERC20Extended } from "../../../lib/common/src/interfaces/IERC20Extended.sol";
import { IMYieldToOne } from "../../../src/projects/yieldToOne/IMYieldToOne.sol";
import { IFreezable } from "../../../src/components/IFreezable.sol";
import { IMExtension } from "../../../src/interfaces/IMExtension.sol";

import { IUSDZ } from "../../../src/vendor/braid/IUSDZ.sol";
import { USDZ } from "../../../src/vendor/braid/USDZ.sol";

import { USDZHarness } from "../../harness/USDZHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract USDZUnitTests is BaseUnitTest {
    USDZHarness public usdz;

    string public constant NAME = "USDZ";
    string public constant SYMBOL = "USDZ";

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public pauser = makeAddr("pauser");
    address public forcedTransferManager = makeAddr("forcedTransferManager");

    function setUp() public override {
        super.setUp();

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

        registrar.setEarner(address(usdz), true);
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertEq(usdz.name(), NAME);
        assertEq(usdz.symbol(), SYMBOL);
        assertEq(usdz.decimals(), 6);
        assertEq(usdz.mToken(), address(mToken));
        assertEq(usdz.swapFacility(), address(swapFacility));
        assertEq(usdz.yieldRecipient(), yieldRecipient);

        assertTrue(IAccessControl(address(usdz)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(IAccessControl(address(usdz)).hasRole(FREEZE_MANAGER_ROLE, freezeManager));
        assertTrue(IAccessControl(address(usdz)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));
        assertTrue(IAccessControl(address(usdz)).hasRole(usdz.PAUSER_ROLE(), pauser));
        assertTrue(IAccessControl(address(usdz)).hasRole(usdz.FORCED_TRANSFER_MANAGER_ROLE(), forcedTransferManager));
    }

    /* ============ claimYield ============ */

    function test_claimYield_onlyYieldRecipientManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                YIELD_RECIPIENT_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        usdz.claimYield();
    }

    function test_claimYield() external {
        uint256 yield = 500e6;

        mToken.setBalanceOf(address(usdz), 1_500e6);
        usdz.setTotalSupply(1_000e6);

        assertEq(usdz.yield(), yield);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(yield);

        vm.prank(yieldRecipientManager);
        assertEq(usdz.claimYield(), yield);

        assertEq(usdz.yield(), 0);

        assertEq(mToken.balanceOf(address(usdz)), 1_500e6);
        assertEq(usdz.totalSupply(), 1_500e6);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(usdz.balanceOf(yieldRecipient), yield);
    }

    /* ============ pause ============ */

    function test_pause_onlyPauser() external {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, usdz.PAUSER_ROLE())
        );

        vm.prank(alice);
        usdz.pause();
    }

    function test_pause() external {
        vm.prank(pauser);
        usdz.pause();

        assertTrue(usdz.paused());
    }

    /* ============ unpause ============ */

    function test_unpause_onlyPauser() external {
        vm.prank(pauser);
        usdz.pause();

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, usdz.PAUSER_ROLE())
        );

        vm.prank(alice);
        usdz.unpause();
    }

    function test_unpause() external {
        vm.prank(pauser);
        usdz.pause();

        vm.prank(pauser);
        usdz.unpause();

        assertFalse(usdz.paused());
    }

    /* ============ wrap ============ */

    function test_wrap_whenPaused() external {
        vm.prank(pauser);
        usdz.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(address(swapFacility));
        usdz.wrap(alice, 1e6);
    }

    function test_wrap() external {
        uint256 amount_ = 1_000e6;
        mToken.setBalanceOf(address(swapFacility), amount_);

        vm.expectCall(
            address(mToken),
            abi.encodeWithSelector(mToken.transferFrom.selector, address(swapFacility), address(usdz), amount_)
        );

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, amount_);

        vm.prank(address(swapFacility));
        usdz.wrap(alice, amount_);

        assertEq(usdz.balanceOf(alice), amount_);
        assertEq(usdz.totalSupply(), amount_);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(usdz)), amount_);
    }

    /* ============ unwrap ============ */

    function test_unwrap_whenPaused() external {
        vm.prank(pauser);
        usdz.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(address(swapFacility));
        usdz.unwrap(alice, 1e6);
    }

    function test_unwrap() external {
        uint256 amount_ = 1_000e6;

        usdz.setBalanceOf(address(swapFacility), amount_);
        usdz.setBalanceOf(alice, amount_);
        usdz.setTotalSupply(amount_);

        mToken.setBalanceOf(address(usdz), amount_);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1e6);

        vm.prank(address(swapFacility));
        usdz.unwrap(alice, 1e6);

        assertEq(usdz.totalSupply(), 999e6);
        assertEq(usdz.balanceOf(address(swapFacility)), 999e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 1e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499e6);

        vm.prank(address(swapFacility));
        usdz.unwrap(alice, 499e6);

        assertEq(usdz.totalSupply(), 500e6);
        assertEq(usdz.balanceOf(address(swapFacility)), 500e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 500e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500e6);

        vm.prank(address(swapFacility));
        usdz.unwrap(alice, 500e6);

        assertEq(usdz.totalSupply(), 0);
        assertEq(usdz.balanceOf(address(swapFacility)), 0);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), amount_);
        assertEq(mToken.balanceOf(address(usdz)), 0);
    }

    /* ============ transfer ============ */

    function test_transfer_whenPaused() external {
        vm.prank(pauser);
        usdz.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(alice);
        usdz.transfer(bob, 1e6);
    }

    function test_transfer() external {
        uint256 amount_ = 1_000e6;
        usdz.setBalanceOf(alice, amount_);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount_);

        vm.prank(alice);
        usdz.transfer(bob, amount_);

        assertEq(usdz.balanceOf(alice), 0);
        assertEq(usdz.balanceOf(bob), amount_);
    }

    /* ============ forceTransfer ============ */

    function test_forceTransfer_revertWhenNotForcedTransferManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                usdz.FORCED_TRANSFER_MANAGER_ROLE()
            )
        );

        vm.prank(admin);
        usdz.forceTransfer(alice, bob, 1e6);
    }

    function test_forceTransfer_revertWhenAccountNotFrozen() external {
        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountNotFrozen.selector, alice));

        vm.prank(forcedTransferManager);
        usdz.forceTransfer(alice, bob, 1e6);
    }

    function test_forceTransfer_revertWhenInvalidRecipient() external {
        vm.prank(freezeManager);
        usdz.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(forcedTransferManager);
        usdz.forceTransfer(alice, address(0), 0);
    }

    function test_forceTransfer_revertWhenInsufficientBalance() external {
        uint256 amount_ = 1_000e6;
        usdz.setBalanceOf(alice, amount_);

        vm.prank(freezeManager);
        usdz.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, amount_, 2 * amount_));

        vm.prank(forcedTransferManager);
        usdz.forceTransfer(alice, bob, 2 * amount_);
    }

    function test_forceTransfer() external {
        uint256 amount_ = 1_000e6;
        usdz.setBalanceOf(alice, amount_);

        vm.prank(freezeManager);
        usdz.freeze(alice);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount_);

        vm.expectEmit();
        emit IUSDZ.ForcedTransfer(alice, bob, forcedTransferManager, amount_);

        vm.prank(forcedTransferManager);
        usdz.forceTransfer(alice, bob, amount_);

        assertEq(usdz.balanceOf(alice), 0);
        assertEq(usdz.balanceOf(bob), amount_);
    }

    /* ============ forceTransfers ============ */

    function test_forceTransfers_revertWhenNotForcedTransferManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                admin,
                usdz.FORCED_TRANSFER_MANAGER_ROLE()
            )
        );

        vm.prank(admin);
        usdz.forceTransfers(new address[](0), new address[](0), new uint256[](0));
    }

    function test_forceTransfers_revertWhenArrayLengthMismatch_v1() external {
        vm.expectRevert(IUSDZ.ArrayLengthMismatch.selector);

        vm.prank(forcedTransferManager);
        usdz.forceTransfers(new address[](1), new address[](0), new uint256[](0));
    }

    function test_forceTransfers_revertWhenArrayLengthMismatch_v2() external {
        vm.expectRevert(IUSDZ.ArrayLengthMismatch.selector);

        vm.prank(forcedTransferManager);
        usdz.forceTransfers(new address[](0), new address[](0), new uint256[](1));
    }

    function test_forceTransfers() external {
        uint256 amount1 = 1_000e6;
        uint256 amount2 = 2_000e6;

        address[] memory frozenAccounts = new address[](2);
        frozenAccounts[0] = alice;
        frozenAccounts[1] = carol;

        address[] memory destinations = new address[](2);
        destinations[0] = bob;
        destinations[1] = charlie;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount1;
        amounts[1] = amount2;

        usdz.setBalanceOf(alice, amount1);
        usdz.setBalanceOf(carol, amount2);

        vm.prank(freezeManager);
        usdz.freeze(alice);

        vm.prank(freezeManager);
        usdz.freeze(carol);

        vm.prank(forcedTransferManager);
        usdz.forceTransfers(frozenAccounts, destinations, amounts);

        assertEq(usdz.balanceOf(alice), 0);
        assertEq(usdz.balanceOf(carol), 0);
        assertEq(usdz.balanceOf(destinations[0]), amount1);
        assertEq(usdz.balanceOf(destinations[1]), amount2);
    }
}
