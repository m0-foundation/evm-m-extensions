// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

import { UIntMath } from "../../lib/common/src/libs/UIntMath.sol";
import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";
import { ContinuousIndexingMath } from "../../lib/common/src/libs/ContinuousIndexingMath.sol";

import { IContinuousIndexing } from "../../src/projects/yieldToAllWithFee/interfaces/IContinuousIndexing.sol";

import { MEarnerManagerHarness } from "../harness/MEarnerManagerHarness.sol";
import { MYieldToOneHarness } from "../harness/MYieldToOneHarness.sol";
import { MYieldFeeHarness } from "../harness/MYieldFeeHarness.sol";

import { BaseIntegrationTest } from "../utils/BaseIntegrationTest.sol";

import { IFreezable } from "../../src/components/IFreezable.sol";

import { ISwapFacility } from "../../src/swap/interfaces/ISwapFacility.sol";

import { console } from "forge-std/console.sol";

contract MExtensionSystemIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    uint128 public mIndexInitial;
    uint128 public mYieldFeeIndexInitial;

    uint32 public mRate;
    uint40 public mRateStart;

    uint32 public mYieldFeeRate;
    uint32 public mYieldFeeIndexStart;

    uint16 public mEarnerFeeRate;

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

        mEarnerManager.enableEarning();
        mYieldFee.enableEarning();
        mYieldToOne.enableEarning();

        mIndexInitial = mToken.currentIndex();
        mYieldFeeIndexInitial = mYieldFee.currentIndex();

        mRate = mToken.earnerRate();
        mRateStart = IContinuousIndexing(address(mToken)).latestUpdateTimestamp();

        mYieldFeeRate = mYieldFee.earnerRate();
        mYieldFeeIndexStart = uint32(vm.getBlockTimestamp());

        _fundAccounts();

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(alice, true, 5_000); // 50% fee

        mEarnerFeeRate = 5_000;

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(address(swapFacility), true, 0);

        vm.prank(admin);
        swapFacility.grantRole(M_SWAPPER_ROLE, alice);
    }

    function calculateMYieldFeeYield(uint256 amount, uint256 start, uint256 end) public view returns (uint256) {}

    function calculateMYieldToOneYield(uint256 amount, uint256 start, uint256 end) public view returns (uint256) {}

    function calculateMYearnerManagerYield(uint256 amount, uint256 start, uint256 end) public view returns (uint256) {}

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
        swapFacility.swap(address(mYieldFee), address(mYieldToOne), mYieldFeeBalance - 2, alice);

        uint256 mYieldToOneBalance = mYieldToOne.balanceOf(alice);
        assertEq(mYieldToOneBalance, 10e6 - 2);

        vm.prank(alice);
        swapFacility.swap(address(mYieldToOne), address(mEarnerManager), mYieldToOneBalance - 2, alice);

        uint256 mEarnerManagerBalance = mEarnerManager.balanceOf(alice);
        assertEq(mEarnerManagerBalance, 10e6 - 4);

        vm.prank(alice);
        swapFacility.swap(address(mEarnerManager), address(wrappedM), mEarnerManagerBalance - 2, alice);

        uint256 wrappedMBalance = wrappedM.balanceOf(alice);
        assertEq(wrappedMBalance, 10e6 - 7);
    }

    function test_yieldFlow_betweenExtensions() public {
        // Setup multiple extensions with different yield configurations
        // Swap between them and verify yield is properly tracked
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

        // fast forward to accrue yield
        vm.warp(vm.getBlockTimestamp() + 72_426_135);

        // check and claim yield from mYieldFee
        uint256 mYieldFeeYield = mYieldFee.accruedYieldOf(alice);
        assertEq(mYieldFeeYield, 894400, "Should have accrued yield in mYieldFee");

        vm.prank(alice);
        swapFacility.swap(address(mYieldFee), address(mYieldToOne), mYieldFeeBalance, alice);

        uint256 mYieldToOneBalance = mYieldToOne.balanceOf(alice);
        assertEq(mYieldToOneBalance, 10e6);

        // fast forward to accrue yield
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // check and claim yield from mYieldToOne
        uint256 mYieldToOneYield = mYieldToOne.yield();
        assertEq(mYieldToOneYield, 11375, "Should have accrued yield in mYieldToOne");

        vm.prank(alice);
        swapFacility.swap(address(mYieldToOne), address(mEarnerManager), mYieldToOneBalance, alice);

        uint256 mEarnerManagerBalance = mEarnerManager.balanceOf(alice);
        assertEq(mEarnerManagerBalance, 10e6);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        (uint256 aliceYieldWithFee, uint256 aliceFee, uint256 aliceYield) = mEarnerManager.accruedYieldAndFeeOf(alice);

        assertEq(aliceYieldWithFee, 11375, "alice's yield with fee should be 11375");
        assertEq(aliceFee, 5687, "alice's fee should be 5687");
        assertEq(aliceYield, 5688, "alice's yield should be 5688");

        vm.prank(alice);
        swapFacility.swap(address(mEarnerManager), address(wrappedM), mEarnerManagerBalance - 2, alice);

        uint256 wrappedMBalance = wrappedM.balanceOf(alice);
        assertEq(wrappedMBalance, 10e6 - 2);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        vm.prank(alice);
        swapFacility.swapOutM(address(wrappedM), wrappedMBalance, alice);

        mEarnerManagerBalance = mEarnerManager.balanceOf(alice);

        assertEq(mEarnerManagerBalance, 2);

        mEarnerManager.claimFor(alice);

        mEarnerManagerBalance = mEarnerManager.balanceOf(alice);

        assertEq(mEarnerManagerBalance, 5696, "alice's claiming should have put her yield in her balance");

        assertEq(
            mEarnerManager.balanceOf(feeRecipient),
            5693,
            "Fee recipient should have fee claimed for on alice's claiming"
        );

        mYieldToOne.claimYield();

        mYieldToOneBalance = mYieldToOne.balanceOf(yieldRecipient);

        assertEq(mYieldToOneBalance, 11401, "yield recipient should have its yield claimed");

        mYieldFee.claimYieldFor(alice);

        mYieldFeeBalance = mYieldFee.balanceOf(alice);

        assertEq(mYieldFeeBalance, 897145, "alice should have her yield claimed");
    }

    uint256 constant M_YIELD_TO_ONE = 0;
    uint256 constant M_YIELD_FEE = 1;
    uint256 constant M_EARNER_MANAGER = 2;

    /// @dev Using lower fuzz runs and depth to avoid burning through RPC requests in CI
    /// forge-config: default.fuzz.runs = 100
    /// forge-config: default.fuzz.depth = 20
    /// forge-config: ci.fuzz.runs = 10
    /// forge-config: ci.fuzz.depth = 2
    function testFuzz_yieldClaim_afterMultipleSwaps(uint256 seed) public {
        vm.startPrank(alice);
        mToken.approve(address(swapFacility), type(uint256).max);
        mYieldFee.approve(address(swapFacility), type(uint256).max);
        mYieldToOne.approve(address(swapFacility), type(uint256).max);
        mEarnerManager.approve(address(swapFacility), type(uint256).max);
        wrappedM.approve(address(swapFacility), type(uint256).max);
        vm.stopPrank();

        function(address, uint256[] memory, uint256) internal returns (uint256, uint256[] memory)[]
            memory yieldAssertions = new function(address, uint256[] memory, uint256)
                internal
                returns (uint256, uint256[] memory)[](3);
        yieldAssertions[M_YIELD_TO_ONE] = _testYieldCapture_mYieldToOne;
        yieldAssertions[M_YIELD_FEE] = _testYieldCapture_mYieldFee;
        yieldAssertions[M_EARNER_MANAGER] = _testYieldCapture_mEarnerManager;

        address[] memory extensions = new address[](3);
        extensions[M_YIELD_TO_ONE] = address(mYieldToOne);
        extensions[M_YIELD_FEE] = address(mYieldFee);
        extensions[M_EARNER_MANAGER] = address(mEarnerManager);

        uint256 amount;

        uint256[] memory yields = new uint256[](3);

        (amount, yields) = yieldAssertions[M_YIELD_TO_ONE](address(mToken), yields, 10e6);

        uint256 extensionIndex;

        for (uint256 i = 0; i < 20; i++) {
            uint256 nextExtensionIndex = uint256(keccak256(abi.encode(seed, i))) % 3;

            if (nextExtensionIndex == extensionIndex) nextExtensionIndex = (nextExtensionIndex + 1) % 3;

            (amount, yields) = yieldAssertions[nextExtensionIndex](extensions[extensionIndex], yields, amount);

            extensionIndex = nextExtensionIndex;
        }

        vm.prank(alice);
        swapFacility.swapOutM(extensions[extensionIndex], amount, alice);

        mYieldToOne.claimYield();
        assertApproxEqAbs(mYieldToOne.balanceOf(yieldRecipient), yields[M_YIELD_TO_ONE], 20);

        mYieldFee.claimYieldFor(alice);
        assertApproxEqAbs(mYieldFee.balanceOf(alice), yields[M_YIELD_FEE], 50);

        mEarnerManager.claimFor(alice);
        assertApproxEqAbs(mEarnerManager.balanceOf(alice), yields[M_EARNER_MANAGER] / 2, 50);
        assertApproxEqAbs(mEarnerManager.balanceOf(feeRecipient), yields[M_EARNER_MANAGER] / 2, 50);
    }

    function test_mYieldFee_feeRecipientChange_duringActiveYield() public {
        vm.prank(alice);
        mToken.approve(address(swapFacility), type(uint256).max);

        address feeRecipient2 = makeAddr("feeRecipient2");

        vm.prank(alice);
        swapFacility.swapInM(address(mYieldFee), 10e6, alice);

        mRateStart = uint40(vm.getBlockTimestamp());

        uint112 _initialMPrincipalInMYieldFee = _calcMPrincipalAmountRoundedUp(10e6 - 2);

        uint112 _initialMYieldFeePrincipal = _calcMYieldFeePrincipal(10e6 - 2);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        uint256 _postWarpMAmountInMYieldFee = _calcMPresentAmountRoundedDown(_initialMPrincipalInMYieldFee);

        uint256 _postWarpMYieldFeeBalance = _calcMYieldFeePresentAmountRoundedDown(_initialMYieldFeePrincipal);

        uint256 _expectedFee = _postWarpMAmountInMYieldFee - _postWarpMYieldFeeBalance;

        vm.prank(feeManager);
        mYieldFee.setFeeRecipient(feeRecipient2);

        assertApproxEqAbs(mYieldFee.balanceOf(feeRecipient), _expectedFee, 3);

        _initialMYieldFeePrincipal += _calcMYieldFeePrincipal(_expectedFee);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        _postWarpMAmountInMYieldFee = _calcMPresentAmountRoundedDown(_initialMPrincipalInMYieldFee);

        _postWarpMYieldFeeBalance = _calcMYieldFeePresentAmountRoundedDown(_initialMYieldFeePrincipal);

        uint256 _balanceWithYield = IndexingMath.getPresentAmountRoundedDown(
            _initialMYieldFeePrincipal,
            _currentMYieldFeeIndex()
        );

        _expectedFee = _postWarpMAmountInMYieldFee - _postWarpMYieldFeeBalance;

        vm.prank(feeManager);
        mYieldFee.setFeeRecipient(feeRecipient);

        assertApproxEqAbs(mYieldFee.balanceOf(feeRecipient), _expectedFee, 3);
    }

    function test_permissionedExtension_fullLifecycle() public {
        vm.startPrank(alice);
        mToken.approve(address(swapFacility), type(uint256).max);
        mYieldFee.approve(address(swapFacility), type(uint256).max);
        mYieldToOne.approve(address(swapFacility), type(uint256).max);
        mEarnerManager.approve(address(swapFacility), type(uint256).max);
        wrappedM.approve(address(swapFacility), type(uint256).max);
        vm.stopPrank();

        vm.prank(admin);
        swapFacility.setPermissionedExtension(address(mYieldToOne), true);

        vm.prank(admin);
        swapFacility.setPermissionedExtension(address(mYieldFee), true);

        vm.prank(admin);
        swapFacility.setPermissionedExtension(address(mEarnerManager), true);

        vm.prank(admin);
        swapFacility.setPermissionedMSwapper(address(mYieldToOne), alice, true);

        vm.prank(admin);
        swapFacility.setPermissionedMSwapper(address(mYieldFee), alice, true);

        vm.prank(admin);
        swapFacility.setPermissionedMSwapper(address(mEarnerManager), alice, true);

        vm.prank(alice);
        swapFacility.swapInM(address(mYieldToOne), 10e6, alice);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(mYieldToOne)));

        vm.prank(alice);
        swapFacility.swap(address(mYieldToOne), address(mYieldFee), 10e6, alice);

        vm.prank(alice);
        swapFacility.swapOutM(address(mYieldToOne), 10e6 - 2, alice);

        vm.prank(alice);
        swapFacility.swapInM(address(mYieldFee), 10e6, alice);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(mYieldFee)));

        vm.prank(alice);
        swapFacility.swap(address(mYieldFee), address(mYieldToOne), 10e6 - 2, alice);

        vm.prank(alice);
        swapFacility.swapOutM(address(mYieldFee), 10e6 - 2, alice);

        vm.prank(alice);
        swapFacility.swapInM(address(mEarnerManager), 10e6, alice);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(mEarnerManager)));

        vm.prank(alice);
        swapFacility.swap(address(mEarnerManager), address(mYieldFee), 10e6 - 2, alice);

        vm.prank(admin);
        swapFacility.setPermissionedMSwapper(address(mEarnerManager), alice, false);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISwapFacility.NotApprovedPermissionedSwapper.selector,
                address(mEarnerManager),
                alice
            )
        );

        vm.prank(alice);
        swapFacility.swapOutM(address(mEarnerManager), 10e6 - 2, alice);

        vm.prank(admin);
        swapFacility.setPermissionedExtension(address(mEarnerManager), false);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(mYieldToOne)));

        vm.prank(alice);
        swapFacility.swap(address(mEarnerManager), address(mYieldToOne), 10e6 - 2, alice);

        vm.prank(admin);
        swapFacility.setPermissionedExtension(address(mYieldToOne), false);

        vm.prank(alice);
        swapFacility.swap(address(mEarnerManager), address(mYieldToOne), 10e6 - 2, alice);

        assertEq(mYieldToOne.balanceOf(alice), 10e6, "mYieldToOne balance should be 10e6");

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.PermissionedExtension.selector, address(mYieldFee)));

        vm.prank(alice);
        swapFacility.swap(address(mYieldToOne), address(mYieldFee), 10e6, alice);

        vm.prank(admin);
        swapFacility.setPermissionedExtension(address(mYieldFee), false);

        vm.prank(alice);
        swapFacility.swap(address(mYieldToOne), address(mYieldFee), 10e6 - 4, alice);

        assertEq(mYieldFee.balanceOf(alice), 10e6 - 2, "mYieldFee balance should be 10e6 - 4");
    }

    function test_mixedPermissions_swapScenarios() public {
        // Mix of permissioned and non-permissioned extensions
        // Test various swap paths
    }

    function test_swapAdapter_withMultipleExtensions() public {
        // Test TOKEN -> USDC -> USDT -> WrappedM -> Extension

        vm.prank(earnerManager);
        mEarnerManager.setAccountInfo(address(swapAdapter), true, 0);

        vm.startPrank(alice);

        // Approve swap adapter for all tokens
        IERC20(USDC).approve(address(swapAdapter), type(uint256).max);
        USDT.call(abi.encodeWithSelector(IERC20.approve.selector, address(swapAdapter), type(uint256).max));

        // Approve swap facility for all extensions
        mToken.approve(address(swapFacility), type(uint256).max);
        wrappedM.approve(address(swapFacility), type(uint256).max);
        mYieldToOne.approve(address(swapFacility), type(uint256).max);
        mYieldFee.approve(address(swapFacility), type(uint256).max);
        mEarnerManager.approve(address(swapFacility), type(uint256).max);

        // Approve swap adapter for all extensions
        mYieldToOne.approve(address(swapAdapter), type(uint256).max);
        mYieldFee.approve(address(swapAdapter), type(uint256).max);
        mEarnerManager.approve(address(swapAdapter), type(uint256).max);
        wrappedM.approve(address(swapAdapter), type(uint256).max);

        vm.stopPrank();

        vm.prank(alice);
        swapFacility.swapInM(address(mYieldToOne), 10e6, alice);

        assertEq(mYieldToOne.balanceOf(alice), 10e6, "mYieldToOne balance should be 10e6");

        vm.prank(alice);
        swapAdapter.swapOut(address(mYieldToOne), 10e6 - 2, USDC, 0, alice, "");

        uint256 usdcBalance = IERC20(USDC).balanceOf(alice);

        assertEq(usdcBalance, 9999631, "USDC balance of alice should be 9999631");

        vm.prank(alice);
        swapAdapter.swapIn(USDC, usdcBalance, address(mYieldToOne), 0, alice, "");

        uint256 yieldToOneBalance = mYieldToOne.balanceOf(alice);

        assertEq(yieldToOneBalance, 9997997, "mYieldToOne balance of alice should be 10e6");

        // Encode path for USDT -> USDC -> Wrapped M
        bytes memory path = abi.encodePacked(
            WRAPPED_M,
            uint24(100), // 0.01% fee
            USDC,
            uint24(100), // 0.01% fee
            USDT
        );

        vm.prank(alice);
        swapAdapter.swapOut(address(mYieldToOne), yieldToOneBalance - 4, USDT, 0, alice, path);

        uint256 usdtBalance = IERC20(USDT).balanceOf(alice);

        assertEq(usdtBalance, 9995377, "usdt balance should be 9995377");

        path = abi.encodePacked(
            USDT,
            uint24(100), // 0.01% fee
            USDC,
            uint24(100), // 0.01% fee
            WRAPPED_M
        );

        vm.prank(alice);
        swapAdapter.swapIn(USDT, usdtBalance, address(mYieldFee), 0, alice, path);

        uint256 mYieldFeeBalance = mYieldFee.balanceOf(alice);

        assertEq(mYieldFeeBalance, 9993988, "mYieldFeeBalance should be 9993988");
    }

    function test_yieldToOne_freeze_duringYield() public {
        vm.startPrank(alice);
        mToken.approve(address(swapFacility), type(uint256).max);
        mYieldToOne.approve(address(swapFacility), type(uint256).max);
        vm.stopPrank();

        vm.prank(alice);
        mYieldToOne.approve(bob, 10e6);

        vm.prank(bob);
        mToken.approve(address(swapFacility), 10e6);

        vm.prank(alice);
        swapFacility.swapInM(address(mYieldToOne), 10e6, alice);

        uint256 mYieldToOneBalance = mYieldToOne.balanceOf(alice);

        assertEq(mYieldToOneBalance, 10e6, "mYieldToOneBalance should be 10e6");

        uint256 mBalanceBefore = mToken.balanceOf(address(mYieldToOne));

        vm.warp(vm.getBlockTimestamp() + 10 days);

        uint256 mBalanceAfter = mToken.balanceOf(address(mYieldToOne));

        uint256 mYieldToOneYield = mYieldToOne.yield();

        console.log(mBalanceBefore, mBalanceAfter, mYieldToOneYield);

        assertEq(mYieldToOneYield, mBalanceAfter - mBalanceBefore - 2, "yield should match increase in m balance");

        vm.expectEmit(true, true, true, true);
        emit IFreezable.Frozen(alice, vm.getBlockTimestamp());

        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        mBalanceAfter = mToken.balanceOf(address(mYieldToOne));

        mYieldToOneYield = mYieldToOne.yield();

        assertEq(mYieldToOneYield, mBalanceAfter - mBalanceBefore - 2, "yield should match increase in m balance");

        mYieldToOne.claimYield();

        assertEq(
            mYieldToOne.balanceOf(yieldRecipient),
            mBalanceAfter - mBalanceBefore - 2,
            "yield should be claimed to yield recipient"
        );

        // Test all freeze revertions except for transfer to alice (will test at end)
        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        swapFacility.swap(address(mYieldToOne), address(mYieldFee), 10e6 - 2, alice);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        mYieldToOne.transfer(bob, 10e6);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        mYieldToOne.approve(bob, 10e6);

        vm.stopPrank();

        vm.startPrank(bob);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        mYieldToOne.transferFrom(alice, bob, 10e6);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        swapFacility.swapInM(address(mYieldToOne), 10e6, alice);

        vm.stopPrank();

        vm.prank(freezeManager);
        mYieldToOne.unfreeze(alice);

        mBalanceBefore = mBalanceAfter;

        vm.warp(vm.getBlockTimestamp() + 10 days);

        mBalanceAfter = mToken.balanceOf(address(mYieldToOne));

        mYieldToOneYield = mYieldToOne.yield();

        assertEq(
            mYieldToOneYield,
            mBalanceAfter - mBalanceBefore,
            "yield should match increase in m balance after unfreeze"
        );

        // Re-freeze again to test transfer from bob to frozen alice
        vm.prank(freezeManager);
        mYieldToOne.freeze(alice);

        vm.startPrank(bob);
        swapFacility.swapInM(address(mYieldToOne), 10e6, bob);

        vm.expectRevert(abi.encodeWithSelector(IFreezable.AccountFrozen.selector, alice));
        mYieldToOne.transfer(alice, 10e6);
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

    function _calcMEarnerManagerPrincipal(uint256 amount) public view returns (uint112) {
        uint128 _index = _currentMIndex();

        return IndexingMath.getPrincipalAmountRoundedDown(uint240(amount), _index);
    }

    function _calcMYearnerManagerYield(uint256 balance, uint112 principal) public view returns (uint256) {
        uint128 currentIndex = _currentMIndex();

        uint256 balanceWithYield = IndexingMath.getPresentAmountRoundedUp(principal, currentIndex);

        // Yield is the difference between present value and current balance
        return balanceWithYield > balance ? balanceWithYield - balance : 0;
    }

    function _calcMYieldFeePrincipal(uint256 amount) public view returns (uint112) {
        uint128 _index = _currentMYieldFeeIndex();

        return IndexingMath.getPrincipalAmountRoundedUp(uint240(amount), _index);
    }

    function _calcMYieldFeeYield(uint256 priorAmount, uint112 _principal) public view returns (uint256) {
        uint128 _index = _currentMYieldFeeIndex();

        uint256 _amountPlusYield = IndexingMath.getPresentAmountRoundedUp(_principal, _index);

        return _amountPlusYield - priorAmount;
    }

    function _currentMYieldFeeIndex() public view returns (uint128) {
        unchecked {
            return
                // NOTE: Cap the index to `type(uint128).max` to prevent overflow in present value math.
                UIntMath.bound128(
                    ContinuousIndexingMath.multiplyIndicesDown(
                        mYieldFeeIndexInitial,
                        ContinuousIndexingMath.getContinuousIndex(
                            ContinuousIndexingMath.convertFromBasisPoints(mYieldFeeRate),
                            uint32(vm.getBlockTimestamp() - mYieldFeeIndexStart)
                        )
                    )
                );
        }
    }

    function divideUp(uint240 x, uint128 index) internal pure returns (uint112 z) {
        unchecked {
            // NOTE: While `uint256(x) * EXP_SCALED_ONE` can technically overflow, these divide/multiply functions are
            //       only used for the purpose of principal/present amount calculations for continuous indexing, and
            //       so for an `x` to be large enough to overflow this, it would have to be a possible result of
            //       `multiplyDown` or `multiplyUp`, which would already satisfy
            //       `uint256(x) * EXP_SCALED_ONE < type(uint240).max`.
            return UIntMath.safe112(((uint256(x) * EXP_SCALED_ONE) + index - 1) / index);
        }
    }

    function _calcMPrincipalAmountRoundedUp(uint256 amount) public view returns (uint112) {
        uint128 _index = _currentMIndex();

        return IndexingMath.getPrincipalAmountRoundedUp(uint240(amount), _index);
    }

    function _calcMPrincipalAmountRoundedDown(uint256 amount) public view returns (uint112) {
        uint128 _index = _currentMIndex();

        return IndexingMath.getPrincipalAmountRoundedDown(uint240(amount), _index);
    }

    function _calcMPresentAmountRoundedDown(uint112 amount) public view returns (uint240) {
        uint128 _index = _currentMIndex();

        return IndexingMath.getPresentAmountRoundedDown(amount, _index);
    }

    function _calcMPresentAmountRoundedUp(uint112 amount) public view returns (uint240) {
        uint128 _index = _currentMIndex();

        return IndexingMath.getPresentAmountRoundedUp(amount, _index);
    }

    function _calcMYieldFeePresentAmountRoundedUp(uint112 amount) public view returns (uint240) {
        uint128 _index = _currentMYieldFeeIndex();

        return IndexingMath.getPresentAmountRoundedUp(amount, _index);
    }

    function _calcMYieldFeePresentAmountRoundedDown(uint112 amount) public view returns (uint240) {
        uint128 _index = _currentMYieldFeeIndex();

        return IndexingMath.getPresentAmountRoundedDown(amount, _index);
    }

    function _currentMIndex() public view returns (uint128) {
        unchecked {
            return
                // NOTE: Cap the index to `type(uint128).max` to prevent overflow in present value math.
                UIntMath.bound128(
                    ContinuousIndexingMath.multiplyIndicesDown(
                        mIndexInitial,
                        ContinuousIndexingMath.getContinuousIndex(
                            ContinuousIndexingMath.convertFromBasisPoints(mRate),
                            uint32(block.timestamp - mRateStart)
                        )
                    )
                );
        }
    }

    function _testYieldCapture_mYieldFee(
        address from,
        uint256[] memory yields,
        uint256 amount
    ) public returns (uint256, uint256[] memory) {
        vm.prank(alice);

        if (from == address(mToken)) swapFacility.swapInM(address(mYieldFee), amount, alice);
        else swapFacility.swap(from, address(mYieldFee), amount, alice);

        // Prep MEarnerManager
        uint112 mEarnerManagerPrincipal = yields[M_EARNER_MANAGER] == 0
            ? 0
            : _calcMEarnerManagerPrincipal(yields[M_EARNER_MANAGER]);

        // Prep MYieldToOne
        uint256 mBalanceBefore = mToken.balanceOf(address(mYieldToOne));

        // Prep MYieldFee
        uint112 _principal = _calcMYieldFeePrincipal(amount + yields[M_YIELD_FEE]);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        // Collect MEarnerManager yield
        yields[M_EARNER_MANAGER] += mEarnerManagerPrincipal == 0
            ? 0
            : _calcMYearnerManagerYield(yields[M_EARNER_MANAGER], mEarnerManagerPrincipal);

        // Collect MYieldToOne yield
        yields[M_YIELD_TO_ONE] += mBalanceBefore == 0 ? 0 : mToken.balanceOf(address(mYieldToOne)) - mBalanceBefore;

        // Collect MYieldFee yield
        uint256 priorYield = yields[M_YIELD_FEE];

        yields[M_YIELD_FEE] += _calcMYieldFeeYield(amount + yields[M_YIELD_FEE], _principal);

        uint256 mYieldFeeYield = mYieldFee.accruedYieldOf(alice);

        assertApproxEqAbs(mYieldFeeYield, yields[M_YIELD_FEE], 50, "Should have accrued yield in mYieldFee");

        return (priorYield == 0 ? amount - 2 : amount, yields);
    }

    function _testYieldCapture_mYieldToOne(
        address from,
        uint256[] memory yields,
        uint256 amount
    ) public returns (uint256, uint256[] memory) {
        vm.prank(alice);
        if (from == address(mToken)) swapFacility.swapInM(address(mYieldToOne), amount, alice);
        else swapFacility.swap(from, address(mYieldToOne), amount, alice);

        // Prep MEarnerManager
        uint112 mEarnerManagerPrincipal = yields[M_EARNER_MANAGER] == 0
            ? 0
            : _calcMEarnerManagerPrincipal(yields[M_EARNER_MANAGER]);

        // Prep MYieldFee
        uint112 mYieldFeePrincipal = yields[M_YIELD_FEE] == 0 ? 0 : _calcMYieldFeePrincipal(yields[M_YIELD_FEE]);

        // Prep MYieldToOne
        uint256 mBalanceBefore = mToken.balanceOf(address(mYieldToOne));

        vm.warp(vm.getBlockTimestamp() + 10 days);

        // Collect MEarnerManager yield
        yields[M_EARNER_MANAGER] += mEarnerManagerPrincipal == 0
            ? 0
            : _calcMYearnerManagerYield(yields[M_EARNER_MANAGER], mEarnerManagerPrincipal);

        // Collect MYieldFee yield
        yields[M_YIELD_FEE] += mYieldFeePrincipal == 0
            ? 0
            : _calcMYieldFeeYield(yields[M_YIELD_FEE], mYieldFeePrincipal);

        // Assert MYieldToOne yield
        uint256 mBalanceAfter = mToken.balanceOf(address(mYieldToOne));

        uint256 mYieldToOneYield = mYieldToOne.yield();

        uint256 priorYield = yields[0];

        uint256 yield = mBalanceAfter - mBalanceBefore;

        assertApproxEqAbs(mYieldToOneYield, yield + priorYield, 50, "Should have accrued yield in mYieldToOne");

        yields[0] += yield;

        return (priorYield == 0 ? amount - 2 : amount, yields);
    }

    function _testYieldCapture_mEarnerManager(
        address from,
        uint256[] memory yields,
        uint256 amount
    ) public returns (uint256, uint256[] memory) {
        vm.prank(alice);
        swapFacility.swap(from, address(mEarnerManager), amount, alice);

        // Prep MYieldFee
        uint112 mYieldFeePrincipal = yields[M_YIELD_FEE] == 0 ? 0 : _calcMYieldFeePrincipal(yields[M_YIELD_FEE]);

        // Prep MYieldToOne
        uint256 mBalanceBefore = yields[M_YIELD_TO_ONE] == 0 ? 0 : mToken.balanceOf(address(mYieldToOne));

        // Prep MYearnerManager
        uint112 principal = _calcMEarnerManagerPrincipal(amount + yields[M_EARNER_MANAGER]);

        vm.warp(vm.getBlockTimestamp() + 10 days);

        // Collect MYieldFee yield
        yields[M_YIELD_FEE] += mYieldFeePrincipal == 0
            ? 0
            : _calcMYieldFeeYield(yields[M_YIELD_FEE], mYieldFeePrincipal);

        // Collect MYieldToOne yield
        yields[M_YIELD_TO_ONE] += mBalanceBefore == 0 ? 0 : mToken.balanceOf(address(mYieldToOne)) - mBalanceBefore;

        // Assert MEarnerManager yield
        uint256 yield = _calcMYearnerManagerYield(amount + yields[M_EARNER_MANAGER], principal);

        (uint256 aliceYieldWithFee, uint256 aliceFee, uint256 aliceYield) = mEarnerManager.accruedYieldAndFeeOf(alice);

        uint256 priorYield = yields[M_EARNER_MANAGER];

        yields[M_EARNER_MANAGER] += yield;

        assertApproxEqAbs(
            aliceYieldWithFee,
            yields[M_EARNER_MANAGER],
            50,
            "unexpected alice's mEarnerManager yield with fee"
        );
        assertApproxEqAbs(aliceFee, yields[M_EARNER_MANAGER] / 2, 50, "unexpected alice's mEarnerManager fee");
        assertApproxEqAbs(aliceYield, yields[M_EARNER_MANAGER] / 2, 50, "unexpected alice's mEarnerManager yield");

        return (priorYield == 0 ? amount - 2 : amount, yields);
    }
}
