// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MEarnerManagerHarness } from "../harness/MEarnerManagerHarness.sol";
import { MYieldToOneHarness } from "../harness/MYieldToOneHarness.sol";
import { MYieldFeeHarness } from "../harness/MYieldFeeHarness.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

import { console } from "forge-std/console.sol";

contract MExtensionSystemIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    function setUp() public override {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_482_175);

        super.setUp();

        _fundAccounts();

        mEarnerManager = MEarnerManagerHarness(
            Upgrades.deployTransparentProxy(
                "MEarnerManagerHarness.sol:MEarnerManagerHarness",
                admin,
                abi.encodeWithSelector(
                    MEarnerManagerHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    admin,
                    earnerManager,
                    feeRecipient
                ),
                mExtensionDeployOptions
            )
        );

        mYieldToOne = MYieldToOneHarness(
            Upgrades.deployTransparentProxy(
                "MYieldToOneHarness.sol:MYieldToOneHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldToOneHarness.initialize.selector,
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

        mYieldFee = MYieldFeeHarness(
            Upgrades.deployTransparentProxy(
                "MYieldFeeHarness.sol:MYieldFeeHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldFeeHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    1e3,
                    feeRecipient,
                    admin,
                    feeManager,
                    claimRecipientManager
                ),
                mExtensionDeployOptions
            )
        );

        _addToList(EARNERS_LIST, address(mYieldFee));
        _addToList(EARNERS_LIST, address(mYieldToOne));
        _addToList(EARNERS_LIST, address(mEarnerManager));
        _fundAccounts();

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 10_000); // 100% fee

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(address(swapFacility), true, 0);

        vm.prank(admin);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);

        mEarnerManager.enableEarning();
    }

    function test_integration_constants_system() external view {
        assertEq(mEarnerManager.name(), NAME);
        assertEq(mEarnerManager.symbol(), SYMBOL);
        assertEq(mEarnerManager.decimals(), 6);
        assertEq(mEarnerManager.mToken(), address(mToken));
        assertEq(mEarnerManager.feeRecipient(), feeRecipient);
        assertEq(mEarnerManager.ONE_HUNDRED_PERCENT(), 10_000);
        assertTrue(mEarnerManager.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mEarnerManager.hasRole(EARNER_MANAGER_ROLE, earnerManager));

        assertEq(mYieldToOne.name(), NAME);
        assertEq(mYieldToOne.symbol(), SYMBOL);
        assertEq(mYieldToOne.decimals(), 6);
        assertEq(mYieldToOne.mToken(), address(mToken));
        assertEq(mYieldToOne.swapFacility(), address(swapFacility));
        assertEq(mYieldToOne.yieldRecipient(), yieldRecipient);
        assertTrue(mYieldToOne.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mYieldToOne.hasRole(FREEZE_MANAGER_ROLE, freezeManager));
        assertTrue(mYieldToOne.hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));

        assertEq(mYieldFee.name(), NAME);
        assertEq(mYieldFee.symbol(), SYMBOL);
        assertEq(mYieldFee.decimals(), 6);
        assertEq(mYieldFee.mToken(), address(mToken));
        assertEq(mYieldFee.feeRecipient(), feeRecipient);
        assertEq(mYieldFee.feeRate(), 1e3);
        assertTrue(mYieldFee.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(mYieldFee.hasRole(FEE_MANAGER_ROLE, feeManager));
        assertTrue(mYieldFee.hasRole(CLAIM_RECIPIENT_MANAGER_ROLE, claimRecipientManager));
    }

    function test_multiHopSwap_mYieldFee_to_mYieldToOne_to_wrappedM() public {
        vm.startPrank(alice);
        mToken.approve(address(swapFacility), 10e6);
        mYieldFee.approve(address(swapFacility), 10e6);
        mYieldToOne.approve(address(swapFacility), 10e6);
        mEarnerManager.approve(address(swapFacility), 10e6);
        wrappedM.approve(address(swapFacility), 10e6);
        vm.stopPrank();

        vm.prank(alice);
        swapFacility.swapInM(address(mYieldFee), 10e6, alice);

        uint256 mYieldFeeBalance = mYieldFee.balanceOf(alice);
        assertEq(mYieldFeeBalance, 10e6);

        vm.prank(alice);
        swapFacility.swap(address(mYieldFee), address(mYieldToOne), 10e6, alice);

        uint256 mYieldToOneBalance = mYieldToOne.balanceOf(alice);
        assertEq(mYieldToOneBalance, 10e6);

        vm.prank(alice);
        swapFacility.swap(address(mYieldToOne), address(mEarnerManager), 10e6, alice);

        uint256 mEarnerManagerBalance = mEarnerManager.balanceOf(alice);
        assertEq(mEarnerManagerBalance, 10e6);
    }

    function test_yieldFlow_betweenExtensions() public {
        // Setup multiple extensions with different yield configurations
        // Swap between them and verify yield is properly tracked
    }

    function test_yieldClaim_afterMultipleSwaps() public {
        // Test yield claim after multiple swaps
    }

    function test_feeCollection_multipleExtensions() public {
        // Test fee collection from multiple extensions
    }

    function test_feeRecipientChange_duringActiveYield() public {
        // Test changing fee recipient while yield is accruing
    }

    function test_permissionedExtension_fullLifecycle() public {
        // Set extension as permissioned
        // Add/remove swappers
        // Test swapping with different users
        // Change permissions mid-lifecycle
    }

    function test_mixedPermissions_swapScenarios() public {
        // Mix of permissioned and non-permissioned extensions
        // Test various swap paths
    }

    function test_multiHopUniswapPath() public {
        // Test TOKEN -> USDC -> USDT -> WrappedM -> Extension
    }

    function test_swapAdapter_withMultipleExtensions() public {
        // Swap from USDC to multiple different extensions
        // Verify routing and balances
    }

    function test_freeze_duringActiveYield() public {
        // Freeze account while yield is accruing
        // Verify yield claim behavior
    }

    function test_freeze_multipleExtensions() public {
        // Freeze user across multiple extensions
        // Test swap attempts between frozen extensions
    }

    function test_whitelistManagement_withActivePositions() public {
        // Whitelist/unwhitelist users with active positions
        // Change fee rates for active users
        // Test batch operations
    }

    function test_rewhitelisting_withAccruedYield() public {
        // Remove from whitelist, let yield accrue, re-whitelist
        // Verify yield distribution
    }

    function test_zeroYieldScenarios() public {
        // Test behavior when yield rate is 0
        // Test swapping with 0 yield accrued
    }

    function test_maxValueScenarios() public {
        // Test with maximum possible balances
        // Test principal/index calculations at extremes
    }

    function test_rapidSwapping() public {
        // Test many swaps in quick succession
        // Verify no precision loss or unexpected behavior
    }

    function test_upgrade_withActiveYield() public {
        // Setup extension with accrued yield
        // Upgrade contract
        // Verify yield is preserved
    }

    function test_upgrade_withFrozenAccounts() public {
        // Freeze accounts, upgrade, verify freeze state
    }

    function test_rateOracle_changes() public {
        // Test behavior when rate oracle updates rates
        // Verify index calculations adjust properly
    }

    function test_roleInteractions_complex() public {
        // Test scenarios where users have multiple roles
        // Test role changes during active operations
    }
}
