// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../../lib/common/src/interfaces/IERC20Extended.sol";

import { ERC20 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {
    IAccessControl
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MockM } from "../../utils/Mocks.sol";

import { MDualBackedToOne } from "../../../src/projects/dualBackedToOne/MDualBackedToOne.sol";
import { IMDualBackedToOne } from "../../../src/projects/dualBackedToOne/IMDualBackedToOne.sol";

import { IFreezable } from "../../../src/components/IFreezable.sol";
import { IMExtension } from "../../../src/interfaces/IMExtension.sol";

import { ISwapFacility } from "../../../src/swap/interfaces/ISwapFacility.sol";

import { MDualBackedToOneHarness } from "../../harness/MDualBackedToOneHarness.sol";

import { BaseUnitTest } from "../../utils/BaseUnitTest.sol";

contract SecondaryERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

contract MYDualBackedToOneUnitTests is BaseUnitTest {
    MDualBackedToOneHarness public mDualBackedToOne;

    string public constant NAME = "HALO USD";
    string public constant SYMBOL = "HALO USD";

    SecondaryERC20 public secondary;

    function setUp() public override {
        super.setUp();

        secondary = new SecondaryERC20("TEST", "TEST");

        mDualBackedToOne = MDualBackedToOneHarness(
            Upgrades.deployTransparentProxy(
                "MDualBackedToOneHarness.sol:MDualBackedToOneHarness",
                admin,
                abi.encodeWithSelector(
                    MDualBackedToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(secondary),
                    admin,
                    collateralManager,
                    yieldRecipientManager,
                    yieldRecipient
                ),
                mExtensionDeployOptions
            )
        );

        registrar.setEarner(address(mDualBackedToOne), true);

        vm.prank(address(swapFacility));
        secondary.approve(address(mDualBackedToOne), type(uint256).max);
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertEq(mDualBackedToOne.name(), NAME);
        assertEq(mDualBackedToOne.symbol(), SYMBOL);
        assertEq(mDualBackedToOne.decimals(), 6);
        assertEq(mDualBackedToOne.mToken(), address(mToken));
        assertEq(mDualBackedToOne.swapFacility(), address(swapFacility));
        assertEq(mDualBackedToOne.yieldRecipient(), yieldRecipient);

        assertTrue(IAccessControl(address(mDualBackedToOne)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(
            IAccessControl(address(mDualBackedToOne)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager)
        );
        assertTrue(IAccessControl(address(mDualBackedToOne)).hasRole(COLLATERAL_MANAGER_ROLE, collateralManager));
    }

    function test_initialize_zeroYieldRecipient_dual() external {
        address implementation = address(new MDualBackedToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedToOne.ZeroYieldRecipient.selector);
        MDualBackedToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(secondary),
                    admin,
                    collateralManager,
                    yieldRecipientManager,
                    address(0)
                )
            )
        );
    }

    function test_initialize_zeroAdmin() external {
        address implementation = address(new MDualBackedToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedToOne.ZeroAdmin.selector);
        MDualBackedToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(secondary),
                    address(0),
                    collateralManager,
                    yieldRecipientManager,
                    address(yieldRecipient)
                )
            )
        );
    }

    function test_initialize_zeroYieldRecipientManager() external {
        address implementation = address(new MDualBackedToOneHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedToOne.ZeroYieldRecipientManager.selector);
        MDualBackedToOneHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedToOne.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(secondary),
                    admin,
                    collateralManager,
                    address(0),
                    address(yieldRecipient)
                )
            )
        );
    }

    /* ============ _wrap ============ */

    function test_wrap() external {
        uint256 amount = 1_000e6;
        mToken.setBalanceOf(address(swapFacility), amount);

        vm.expectCall(
            address(mToken),
            abi.encodeWithSelector(
                mToken.transferFrom.selector,
                address(swapFacility),
                address(mDualBackedToOne),
                amount
            )
        );

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, amount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrap(alice, amount);

        assertEq(mDualBackedToOne.balanceOf(alice), amount);
        assertEq(mDualBackedToOne.totalSupply(), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mDualBackedToOne)), amount);
    }

    /* ============ _wrapSecondary ============ */

    function test_wrap_secondary() public {
        uint256 amount = 1_000e6;
        uint256 secondaryAmount = amount * 1e12;
        secondary.mint(address(swapFacility), secondaryAmount);

        vm.expectCall(
            address(secondary),
            abi.encodeWithSelector(
                secondary.transferFrom.selector,
                address(swapFacility),
                address(mDualBackedToOne),
                secondaryAmount
            )
        );

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, amount);

        vm.prank(address(swapFacility));
        mDualBackedToOne.wrapSecondary(alice, amount);

        assertEq(mDualBackedToOne.balanceOf(alice), amount);
        assertEq(mDualBackedToOne.totalSupply(), amount);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(secondary.balanceOf(address(mDualBackedToOne)), secondaryAmount);
    }

    /* ============ _unwrap ============ */

    function test_unwrap() external {
        uint256 amount = 1_000e6;

        mDualBackedToOne.setBalanceOf(address(swapFacility), amount);
        mDualBackedToOne.setBalanceOf(alice, amount);
        mDualBackedToOne.setTotalSupply(amount);

        mToken.setBalanceOf(address(mDualBackedToOne), amount);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 1e6);

        assertEq(mDualBackedToOne.totalSupply(), 999e6);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 999e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 1e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 499e6);

        assertEq(mDualBackedToOne.totalSupply(), 500e6);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 500e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 500e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 500e6);

        assertEq(mDualBackedToOne.totalSupply(), 0);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 0);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), amount);
        assertEq(mToken.balanceOf(address(mDualBackedToOne)), 0);
    }

    function test_unwrap_with_only_secondary_backing() public {
        uint256 amount = 1_000e6;
        uint256 secondaryAmount = amount * 1e12;

        mDualBackedToOne.setBalanceOf(address(swapFacility), amount);
        mDualBackedToOne.setBalanceOf(alice, amount);
        mDualBackedToOne.setTotalSupply(amount);
        mDualBackedToOne.setSecondarySupply(amount);

        secondary.mint(address(mDualBackedToOne), secondaryAmount);

        vm.expectRevert(abi.encodeWithSelector(IMDualBackedToOne.InsufficientMBacking.selector));

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 1e6);
    }

    function test_unwrap_with_secondary_backing() public {
        uint256 amount = 1_000e6;
        uint256 secondaryAmount = amount * 1e12;

        mDualBackedToOne.setBalanceOf(address(swapFacility), 2 * amount);
        mDualBackedToOne.setTotalSupply(2 * amount);
        mDualBackedToOne.setSecondarySupply(amount);

        mToken.setBalanceOf(address(mDualBackedToOne), amount);
        secondary.mint(address(mDualBackedToOne), secondaryAmount);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 1e6);

        assertEq(mDualBackedToOne.totalSupply(), 999e6 + amount);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 999e6 + amount);
        assertEq(mToken.balanceOf(address(swapFacility)), 1e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 499e6);

        assertEq(mDualBackedToOne.totalSupply(), 500e6 + amount);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 500e6 + amount);
        assertEq(mToken.balanceOf(address(swapFacility)), 500e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500e6);

        vm.prank(address(swapFacility));
        mDualBackedToOne.unwrap(alice, 500e6);

        assertEq(mDualBackedToOne.totalSupply(), 0 + amount);
        assertEq(mDualBackedToOne.balanceOf(address(swapFacility)), 0 + amount);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), amount);
        assertEq(mToken.balanceOf(address(mDualBackedToOne)), 0);
    }

    /* ============ _transfer ============ */

    function test_transfer() external {
        uint256 amount = 1_000e6;
        mDualBackedToOne.setBalanceOf(alice, amount);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount);

        vm.prank(alice);
        mDualBackedToOne.transfer(bob, amount);

        assertEq(mDualBackedToOne.balanceOf(alice), 0);
        assertEq(mDualBackedToOne.balanceOf(bob), amount);
    }

    function testFuzz_transfer(uint256 supply, uint256 aliceBalance, uint256 transferAmount) external {
        supply = bound(supply, 1, type(uint240).max);
        aliceBalance = bound(aliceBalance, 1, supply);
        transferAmount = bound(transferAmount, 1, aliceBalance);
        uint256 bobBalance = supply - aliceBalance;

        if (bobBalance == 0) return;

        mDualBackedToOne.setBalanceOf(alice, aliceBalance);
        mDualBackedToOne.setBalanceOf(bob, bobBalance);

        vm.prank(alice);
        mDualBackedToOne.transfer(bob, transferAmount);

        assertEq(mDualBackedToOne.balanceOf(alice), aliceBalance - transferAmount);
        assertEq(mDualBackedToOne.balanceOf(bob), bobBalance + transferAmount);
    }

    /* ============ yield ============ */
    function test_yield() external {
        assertEq(mDualBackedToOne.yield(), 0);

        mToken.setBalanceOf(address(mDualBackedToOne), 1_500e6);
        mDualBackedToOne.setTotalSupply(1_000e6);

        assertEq(mDualBackedToOne.yield(), 500e6);
    }

    function testFuzz_yield(uint256 mBalance, uint256 totalSupply) external {
        mBalance = bound(mBalance, 0, type(uint240).max);
        totalSupply = bound(totalSupply, 0, mBalance);

        mToken.setBalanceOf(address(mDualBackedToOne), mBalance);
        mDualBackedToOne.setTotalSupply(totalSupply);

        assertEq(mDualBackedToOne.yield(), mBalance - totalSupply);
    }

    /* ============ claimYield ============ */
    function test_claimYield_noYield() external {
        vm.prank(alice);
        uint256 yield = mDualBackedToOne.claimYield();

        assertEq(yield, 0);
    }

    function test_claimYield() external {
        uint256 yield = 500e6;

        mToken.setBalanceOf(address(mDualBackedToOne), 1_500e6);
        mDualBackedToOne.setTotalSupply(1_000e6);

        assertEq(mDualBackedToOne.yield(), yield);

        vm.expectEmit();
        emit IMDualBackedToOne.YieldClaimed(yield);

        assertEq(mDualBackedToOne.claimYield(), yield);

        assertEq(mDualBackedToOne.yield(), 0);

        assertEq(mToken.balanceOf(address(mDualBackedToOne)), 1_500e6);
        assertEq(mDualBackedToOne.totalSupply(), 1_500e6);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mDualBackedToOne.balanceOf(yieldRecipient), yield);
    }

    function test_claimYield_withSecondary() external {
        uint256 yield = 500e6;

        secondary.mint(address(mDualBackedToOne), 1_500e18);
        mToken.setBalanceOf(address(mDualBackedToOne), 1_500e6);
        mDualBackedToOne.setTotalSupply(2_500e6);
        mDualBackedToOne.setSecondarySupply(1_500e6);

        assertEq(mDualBackedToOne.yield(), yield);

        vm.expectEmit();
        emit IMDualBackedToOne.YieldClaimed(yield);

        assertEq(mDualBackedToOne.claimYield(), yield);

        assertEq(mDualBackedToOne.yield(), 0);

        assertEq(mToken.balanceOf(address(mDualBackedToOne)), 1_500e6);
        assertEq(mDualBackedToOne.totalSupply(), 3_000e6);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mDualBackedToOne.balanceOf(yieldRecipient), yield);
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
        mDualBackedToOne.setYieldRecipient(alice);
    }

    function test_setYieldRecipient_zeroYieldRecipient() public {
        vm.expectRevert(IMDualBackedToOne.ZeroYieldRecipient.selector);

        vm.prank(yieldRecipientManager);
        mDualBackedToOne.setYieldRecipient(address(0));
    }

    function test_setYieldRecipient_noUpdate() public {
        assertEq(mDualBackedToOne.yieldRecipient(), yieldRecipient);

        vm.prank(yieldRecipientManager);
        mDualBackedToOne.setYieldRecipient(yieldRecipient);

        assertEq(mDualBackedToOne.yieldRecipient(), yieldRecipient);
    }

    function test_setYieldRecipient() public {
        assertEq(mDualBackedToOne.yieldRecipient(), yieldRecipient);

        vm.expectEmit();
        emit IMDualBackedToOne.YieldRecipientSet(alice);

        vm.prank(yieldRecipientManager);
        mDualBackedToOne.setYieldRecipient(alice);

        assertEq(mDualBackedToOne.yieldRecipient(), alice);
    }

    function test_setYieldRecipient_claimYield() public {
        assertEq(mDualBackedToOne.yieldRecipient(), yieldRecipient);

        mToken.setBalanceOf(address(mDualBackedToOne), mDualBackedToOne.totalSupply() + 500);

        vm.expectEmit();
        emit IMDualBackedToOne.YieldClaimed(500);

        vm.prank(yieldRecipientManager);
        mDualBackedToOne.setYieldRecipient(alice);

        assertEq(mDualBackedToOne.yieldRecipient(), alice);
        assertEq(mDualBackedToOne.yield(), 0);
        assertEq(mDualBackedToOne.balanceOf(yieldRecipient), 500);
    }
}
