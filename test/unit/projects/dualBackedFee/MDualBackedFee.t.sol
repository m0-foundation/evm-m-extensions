// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import {
    IAccessControl
} from "../../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { ERC20 } from "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { Upgrades, UnsafeUpgrades } from "../../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IndexingMath } from "../../../../lib/common/src/libs/IndexingMath.sol";
import { UIntMath } from "../../../../lib/common/src/libs/UIntMath.sol";
import { ContinuousIndexingMath } from "../../../../lib/common/src/libs/ContinuousIndexingMath.sol";

import { IMExtension } from "../../../../src/interfaces/IMExtension.sol";
import { IMTokenLike } from "../../../../src/interfaces/IMTokenLike.sol";
import { IMDualBackedFee } from "../../../../src/projects/dualBackedFee/interfaces/IMDualBackedFee.sol";
import { ISwapFacility } from "../../../../src/swap/interfaces/ISwapFacility.sol";

import { IERC20 } from "../../../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../../../lib/common/src/interfaces/IERC20Extended.sol";

import { MDualBackedFeeHarness } from "../../../harness/MDualBackedFeeHarness.sol";
import { BaseUnitTest } from "../../../utils/BaseUnitTest.sol";

contract SecondaryERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

contract MDualBackedFeeUnitTests is BaseUnitTest {
    MDualBackedFeeHarness public MDualBackedFee;

    SecondaryERC20 SECONDARY;

    function setUp() public override {
        super.setUp();

        SECONDARY = new SecondaryERC20("TEST", "TEST");

        MDualBackedFee = MDualBackedFeeHarness(
            Upgrades.deployTransparentProxy(
                "MDualBackedFeeHarness.sol:MDualBackedFeeHarness",
                admin,
                abi.encodeWithSelector(
                    MDualBackedFeeHarness.initialize.selector,
                    "MDualBackedFee",
                    "MDBF",
                    YIELD_FEE_RATE,
                    feeRecipient,
                    admin,
                    feeManager,
                    claimRecipientManager,
                    collateralManager,
                    IERC20(address(SECONDARY))
                ),
                mExtensionDeployOptions
            )
        );

        registrar.setEarner(address(MDualBackedFee), true);
    }

    /* ============ initialize ============ */

    function test_initialize_fee() external view {
        assertEq(MDualBackedFee.ONE_HUNDRED_PERCENT(), 10_000);
        assertEq(MDualBackedFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(MDualBackedFee.feeRate(), YIELD_FEE_RATE);
        assertEq(MDualBackedFee.feeRecipient(), feeRecipient);
        assertTrue(MDualBackedFee.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(MDualBackedFee.hasRole(FEE_MANAGER_ROLE, feeManager));
        assertTrue(MDualBackedFee.hasRole(CLAIM_RECIPIENT_MANAGER_ROLE, claimRecipientManager));
    }

    function test_initialize_zeroFeeRecipient() external {
        address implementation = address(new MDualBackedFeeHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedFee.ZeroFeeRecipient.selector);
        MDualBackedFeeHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedFeeHarness.initialize.selector,
                    "MDualBackedFee",
                    "MYF",
                    YIELD_FEE_RATE,
                    address(0),
                    admin,
                    feeManager,
                    claimRecipientManager,
                    collateralManager,
                    IERC20(address(SECONDARY))
                )
            )
        );
    }

    function test_initialize_zeroAdmin() external {
        address implementation = address(new MDualBackedFeeHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedFee.ZeroAdmin.selector);
        MDualBackedFeeHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedFeeHarness.initialize.selector,
                    "MDualBackedFee",
                    "MYF",
                    YIELD_FEE_RATE,
                    feeRecipient,
                    address(0),
                    feeManager,
                    claimRecipientManager,
                    collateralManager,
                    IERC20(address(SECONDARY))
                )
            )
        );
    }

    function test_initialize_zeroFeeManager() external {
        address implementation = address(new MDualBackedFeeHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedFee.ZeroFeeManager.selector);
        MDualBackedFeeHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedFeeHarness.initialize.selector,
                    "MDualBackedFee",
                    "MYF",
                    YIELD_FEE_RATE,
                    feeRecipient,
                    admin,
                    address(0),
                    claimRecipientManager,
                    collateralManager,
                    IERC20(address(SECONDARY))
                )
            )
        );
    }

    function test_initialize_zeroClaimRecipientManager() external {
        address implementation = address(new MDualBackedFeeHarness(address(mToken), address(swapFacility)));

        vm.expectRevert(IMDualBackedFee.ZeroClaimRecipientManager.selector);
        MDualBackedFeeHarness(
            UnsafeUpgrades.deployTransparentProxy(
                implementation,
                admin,
                abi.encodeWithSelector(
                    MDualBackedFeeHarness.initialize.selector,
                    "MDualBackedFee",
                    "MYF",
                    YIELD_FEE_RATE,
                    feeRecipient,
                    admin,
                    feeManager,
                    address(0),
                    collateralManager,
                    IERC20(address(SECONDARY))
                )
            )
        );
    }

    /* ============ claimYieldFor ============ */

    function test_claimYieldFor_zeroYieldRecipient() external {
        vm.expectRevert(IMDualBackedFee.ZeroAccount.selector);
        MDualBackedFee.claimYieldFor(address(0));
    }

    function test_claimYieldFor_noYield() external {
        assertEq(MDualBackedFee.claimYieldFor(alice), 0);
    }

    function test_claimYieldFor() external {
        uint240 yieldAmount = 79_230399;
        uint240 aliceBalance = 1_000e6;

        mToken.setBalanceOf(address(MDualBackedFee), yieldAmount);
        MDualBackedFee.setAccountOf(alice, aliceBalance, 1_000e6);
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        vm.expectEmit();
        emit IMDualBackedFee.YieldClaimed(alice, alice, yieldAmount);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimYieldFor(alice), yieldAmount);

        aliceBalance += yieldAmount;

        assertEq(MDualBackedFee.balanceOf(alice), aliceBalance);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 0);

        // 8.5% M Yield Fee index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(MDualBackedFee.currentIndex(), 1_164738254609);

        yieldAmount = 85_507855;

        vm.expectEmit();
        emit IMDualBackedFee.YieldClaimed(alice, alice, yieldAmount);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimYieldFor(alice), yieldAmount);

        aliceBalance += yieldAmount;

        assertEq(MDualBackedFee.balanceOf(alice), aliceBalance);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 0);
    }

    function test_claimYieldFor_claimRecipient() external {
        uint240 yieldAmount = 79_230399;
        uint240 aliceBalance = 1_000e6;
        uint240 bobBalance = 0;
        uint240 carolBalance = 0;

        mToken.setBalanceOf(address(MDualBackedFee), yieldAmount);
        MDualBackedFee.setAccountOf(alice, aliceBalance, 1_000e6);
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        assertEq(MDualBackedFee.claimRecipientFor(alice), alice);

        vm.prank(claimRecipientManager);
        MDualBackedFee.setClaimRecipient(alice, bob);

        assertEq(MDualBackedFee.claimRecipientFor(alice), bob);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        assertEq(MDualBackedFee.accruedYieldOf(alice), yieldAmount);

        vm.expectEmit();
        emit IMDualBackedFee.YieldClaimed(alice, bob, yieldAmount);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), bob, yieldAmount);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimYieldFor(alice), yieldAmount);

        bobBalance += yieldAmount;

        assertEq(MDualBackedFee.balanceOf(alice), aliceBalance);
        assertEq(MDualBackedFee.balanceOf(bob), bobBalance);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 0);

        vm.prank(claimRecipientManager);
        MDualBackedFee.setClaimRecipient(alice, carol);

        // 8.5% M Yield Fee index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(MDualBackedFee.currentIndex(), 1_164738254609);

        yieldAmount = 79_230399;
        uint240 bobYieldAmount = 6_277456;

        assertEq(MDualBackedFee.claimRecipientFor(alice), carol);

        assertEq(MDualBackedFee.accruedYieldOf(alice), yieldAmount);
        assertEq(MDualBackedFee.accruedYieldOf(bob), bobYieldAmount);

        vm.expectEmit();
        emit IMDualBackedFee.YieldClaimed(alice, carol, yieldAmount);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), carol, yieldAmount);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimYieldFor(alice), yieldAmount);

        carolBalance += yieldAmount;

        assertEq(MDualBackedFee.balanceOf(alice), aliceBalance);
        assertEq(MDualBackedFee.balanceOf(bob), bobBalance);
        assertEq(MDualBackedFee.balanceOf(carol), carolBalance);

        assertEq(MDualBackedFee.accruedYieldOf(alice), 0);
        assertEq(MDualBackedFee.accruedYieldOf(bob), bobYieldAmount);
    }

    function testFuzz_claimYieldFor(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 balanceWithYield,
        uint240 balance
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (balanceWithYield, balance) = _getFuzzedBalances(
            currentIndex,
            balanceWithYield,
            balance,
            _getMaxAmount(currentIndex)
        );

        _setupAccount(alice, balanceWithYield, balance);

        uint256 yieldAmount = MDualBackedFee.accruedYieldOf(alice);

        if (yieldAmount != 0) {
            vm.expectEmit();
            emit IMDualBackedFee.YieldClaimed(alice, alice, yieldAmount);
        }

        uint256 aliceBanceBefore = MDualBackedFee.balanceOf(alice);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimYieldFor(alice), yieldAmount);

        assertEq(MDualBackedFee.balanceOf(alice), aliceBanceBefore + yieldAmount);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 0);
    }

    /* ============ claimFee ============ */

    function test_claimFee_noYield() external {
        assertEq(MDualBackedFee.claimFee(), 0);
    }

    function test_claimFee() external {
        uint256 yieldFeeAmount = 20_769600;

        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        // 1_100e6 balance with yield without fee.
        MDualBackedFee.setTotalSupply(1_000e6);
        MDualBackedFee.setTotalPrincipal(1_000e6);
        assertEq(MDualBackedFee.totalAccruedYield(), 79_230399); // Should be 100 - 100 * 20% = 80 but it rounds down

        mToken.setBalanceOf(address(MDualBackedFee), 1_100e6);
        assertEq(MDualBackedFee.totalAccruedFee(), yieldFeeAmount);

        vm.expectEmit();
        emit IMDualBackedFee.FeeClaimed(alice, feeRecipient, yieldFeeAmount);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimFee(), yieldFeeAmount);

        assertEq(MDualBackedFee.balanceOf(feeRecipient), yieldFeeAmount);
        assertEq(MDualBackedFee.totalAccruedFee(), 0);

        // 8.5% M Yield Fee index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(MDualBackedFee.currentIndex(), 1_164738254609);

        assertEq(MDualBackedFee.totalAccruedYield(), 166_383838);

        uint256 secondYieldFeeAmount = 22_846561;

        // 1_210e6 balance with yield without fee.
        mToken.setBalanceOf(address(MDualBackedFee), 1_210e6);
        assertEq(MDualBackedFee.totalAccruedFee(), secondYieldFeeAmount);

        vm.expectEmit();
        emit IMDualBackedFee.FeeClaimed(alice, feeRecipient, secondYieldFeeAmount);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimFee(), secondYieldFeeAmount);

        assertEq(MDualBackedFee.balanceOf(feeRecipient), yieldFeeAmount + secondYieldFeeAmount);
        assertEq(MDualBackedFee.totalAccruedFee(), 0);
    }

    function testFuzz_claimFee(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 totalSupplyWithYield,
        uint240 totalSupply,
        uint240 mBalance
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        uint240 maxAmount = _getMaxAmount(currentIndex);

        (totalSupplyWithYield, totalSupply) = _getFuzzedBalances(
            currentIndex,
            totalSupplyWithYield,
            totalSupply,
            maxAmount
        );

        _setupSupply(totalSupplyWithYield, totalSupply);
        mToken.setBalanceOf(address(MDualBackedFee), mBalance);

        uint256 projectedTotalSupply = MDualBackedFee.projectedTotalSupply();

        vm.assume(mBalance > projectedTotalSupply);

        uint256 totalAccruedFee = mBalance - projectedTotalSupply;

        vm.assume(uint256(totalSupplyWithYield) + totalAccruedFee <= maxAmount);

        uint256 yieldFeeAmount = MDualBackedFee.totalAccruedFee();

        if (yieldFeeAmount != 0) {
            vm.expectEmit();
            emit IMDualBackedFee.FeeClaimed(alice, feeRecipient, yieldFeeAmount);

            vm.expectEmit();
            emit IERC20.Transfer(address(0), feeRecipient, yieldFeeAmount);
        }

        uint256 feeRecipientBalanceBefore = MDualBackedFee.balanceOf(feeRecipient);

        vm.prank(alice);
        assertEq(MDualBackedFee.claimFee(), yieldFeeAmount);

        assertEq(MDualBackedFee.balanceOf(feeRecipient), feeRecipientBalanceBefore + yieldFeeAmount);
        assertEq(MDualBackedFee.totalSupply(), totalSupply + yieldFeeAmount);
        assertEq(MDualBackedFee.totalAccruedFee(), 0);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_earningIsEnabled() external {
        MDualBackedFee.setIsEarningEnabled(true);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.EarningIsEnabled.selector));
        MDualBackedFee.enableEarning();
    }

    function test_enableEarning() external {
        assertEq(MDualBackedFee.currentIndex(), EXP_SCALED_ONE);
        assertEq(MDualBackedFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(MDualBackedFee.latestRate(), 0);

        vm.expectEmit();
        emit IMExtension.EarningEnabled(EXP_SCALED_ONE);

        MDualBackedFee.enableEarning();

        assertEq(MDualBackedFee.currentIndex(), EXP_SCALED_ONE);
        assertEq(MDualBackedFee.latestIndex(), EXP_SCALED_ONE);
        assertEq(MDualBackedFee.latestRate(), mYiedFeeEarnerRate);

        vm.warp(30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_earningIsDisabled() external {
        vm.expectRevert(IMExtension.EarningIsDisabled.selector);
        MDualBackedFee.disableEarning();
    }

    function test_disableEarning() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);
        MDualBackedFee.setLatestIndex(1_100000000000);

        assertEq(MDualBackedFee.currentIndex(), 1_100000000000);
        assertEq(MDualBackedFee.latestIndex(), 1_100000000000);
        assertEq(MDualBackedFee.latestRate(), mYiedFeeEarnerRate);

        vm.warp(30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_187153439146);

        vm.expectEmit();
        emit IMExtension.EarningDisabled(1_187153439146);

        MDualBackedFee.disableEarning();

        assertFalse(MDualBackedFee.isEarningEnabled());
        assertEq(MDualBackedFee.currentIndex(), 1_187153439146);
        assertEq(MDualBackedFee.latestIndex(), 1_187153439146);
        assertEq(MDualBackedFee.latestRate(), 0);

        vm.warp(30_057_038 * 2);

        // Index should not change
        assertEq(MDualBackedFee.currentIndex(), 1_187153439146);
        assertEq(MDualBackedFee.updateIndex(), 1_187153439146);

        // State should not change after updating the index
        assertEq(MDualBackedFee.currentIndex(), 1_187153439146);
        assertEq(MDualBackedFee.latestIndex(), 1_187153439146);
        assertEq(MDualBackedFee.latestRate(), 0);
    }

    /* ============ setFeeRate ============ */

    function test_setFeeRate_onlyYieldFeeManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, FEE_MANAGER_ROLE)
        );

        vm.prank(alice);
        MDualBackedFee.setFeeRate(0);
    }

    function test_setFeeRate_feeRateTooHigh() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IMDualBackedFee.FeeRateTooHigh.selector,
                ONE_HUNDRED_PERCENT + 1,
                ONE_HUNDRED_PERCENT
            )
        );

        vm.prank(feeManager);
        MDualBackedFee.setFeeRate(ONE_HUNDRED_PERCENT + 1);
    }

    function test_setFeeRate_noUpdate() external {
        assertEq(MDualBackedFee.feeRate(), YIELD_FEE_RATE);

        vm.prank(feeManager);
        MDualBackedFee.setFeeRate(YIELD_FEE_RATE);

        assertEq(MDualBackedFee.feeRate(), YIELD_FEE_RATE);
    }

    function test_setFeeRate() external {
        // Reset rate
        vm.prank(feeManager);
        MDualBackedFee.setFeeRate(0);

        vm.expectEmit();
        emit IMDualBackedFee.FeeRateSet(YIELD_FEE_RATE);

        vm.prank(feeManager);
        MDualBackedFee.setFeeRate(YIELD_FEE_RATE);

        assertEq(MDualBackedFee.feeRate(), YIELD_FEE_RATE);
    }

    /* ============ setFeeRecipient ============ */

    function test_setFeeRecipient_onlyFeeManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, FEE_MANAGER_ROLE)
        );

        vm.prank(alice);
        MDualBackedFee.setFeeRecipient(alice);
    }

    function test_setFeeRecipient_zeroFeeRecipient() external {
        vm.expectRevert(IMDualBackedFee.ZeroFeeRecipient.selector);

        vm.prank(feeManager);
        MDualBackedFee.setFeeRecipient(address(0));
    }

    function test_setFeeRecipient_noUpdate() external {
        assertEq(MDualBackedFee.feeRecipient(), feeRecipient);

        vm.prank(feeManager);
        MDualBackedFee.setFeeRecipient(feeRecipient);

        assertEq(MDualBackedFee.feeRecipient(), feeRecipient);
    }

    function test_setFeeRecipient() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        mToken.setBalanceOf(address(MDualBackedFee), 1_100e6);

        uint256 yieldFee = MDualBackedFee.totalAccruedFee();

        address newYieldFeeRecipient = makeAddr("newYieldFeeRecipient");

        vm.expectEmit();
        emit IMDualBackedFee.FeeClaimed(feeManager, feeRecipient, yieldFee);

        vm.expectEmit();
        emit IMDualBackedFee.FeeRecipientSet(newYieldFeeRecipient);

        vm.prank(feeManager);
        MDualBackedFee.setFeeRecipient(newYieldFeeRecipient);

        assertEq(MDualBackedFee.feeRecipient(), newYieldFeeRecipient);
    }

    /* ============ setClaimRecipient ============ */

    function test_setClaimRecipient_onlyClaimRecipientManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                CLAIM_RECIPIENT_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        MDualBackedFee.setClaimRecipient(alice, bob);
    }

    function test_setClaimRecipient_zeroAccount() external {
        vm.expectRevert(IMDualBackedFee.ZeroAccount.selector);

        vm.prank(claimRecipientManager);
        MDualBackedFee.setClaimRecipient(address(0), alice);
    }

    function test_setClaimRecipient_zeroClaimRecipient() external {
        vm.expectRevert(IMDualBackedFee.ZeroClaimRecipient.selector);

        vm.prank(claimRecipientManager);
        MDualBackedFee.setClaimRecipient(alice, address(0));
    }

    function test_setClaimRecipient() external {
        address newClaimRecipient = makeAddr("newClaimRecipient");
        assertEq(MDualBackedFee.claimRecipientFor(alice), alice);

        vm.expectEmit();
        emit IMDualBackedFee.ClaimRecipientSet(alice, newClaimRecipient); // default claim recipient is the account itself

        vm.prank(claimRecipientManager);
        MDualBackedFee.setClaimRecipient(alice, newClaimRecipient);

        assertEq(MDualBackedFee.claimRecipientFor(alice), newClaimRecipient);
    }

    function test_setClaimRecipient_claimYield() external {
        uint240 yieldAmount = 79_230399;
        uint240 aliceBalance = 1_000e6;

        mToken.setBalanceOf(address(MDualBackedFee), yieldAmount);
        MDualBackedFee.setAccountOf(alice, aliceBalance, 1_000e6);
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% index growth
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        vm.expectEmit();
        emit IMDualBackedFee.YieldClaimed(alice, alice, yieldAmount);

        vm.prank(claimRecipientManager);
        MDualBackedFee.setClaimRecipient(alice, bob);

        assertEq(MDualBackedFee.balanceOf(alice), aliceBalance + yieldAmount);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 0);

        vm.prank(alice);
        uint256 yield = MDualBackedFee.claimYieldFor(alice);
        assertEq(yield, 0);
    }

    /* ============ currentIndex ============ */

    function test_currentIndex() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        uint256 expectedIndex = EXP_SCALED_ONE;
        assertEq(MDualBackedFee.currentIndex(), expectedIndex);

        uint256 nextTimestamp = vm.getBlockTimestamp() + 365 days;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(EXP_SCALED_ONE, mYiedFeeEarnerRate, startTimestamp);

        assertEq(MDualBackedFee.currentIndex(), expectedCurrentIndex);
        assertEq(MDualBackedFee.updateIndex(), expectedCurrentIndex);

        uint40 previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 2;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(expectedCurrentIndex, mYiedFeeEarnerRate, previousTimestamp);

        assertEq(MDualBackedFee.currentIndex(), expectedCurrentIndex);

        // Half the earner rate
        mToken.setEarnerRate(M_EARNER_RATE / 2);
        mYiedFeeEarnerRate = _getEarnerRate(M_EARNER_RATE / 2, YIELD_FEE_RATE);

        assertEq(MDualBackedFee.updateIndex(), expectedCurrentIndex);
        assertEq(MDualBackedFee.latestRate(), mYiedFeeEarnerRate);

        previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 3;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(expectedCurrentIndex, mYiedFeeEarnerRate, previousTimestamp);

        assertEq(MDualBackedFee.currentIndex(), expectedCurrentIndex);
        assertEq(MDualBackedFee.updateIndex(), expectedCurrentIndex);

        // Disable earning
        MDualBackedFee.disableEarning();

        previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 4;
        vm.warp(nextTimestamp);

        // Index should not change
        assertEq(MDualBackedFee.currentIndex(), expectedCurrentIndex);

        // Re-enable earning
        mToken.setEarnerRate(M_EARNER_RATE);
        MDualBackedFee.enableEarning();

        mYiedFeeEarnerRate = _getEarnerRate(M_EARNER_RATE, YIELD_FEE_RATE);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        assertEq(MDualBackedFee.updateIndex(), expectedCurrentIndex);

        // Index was just re-enabled, so value should still be the same
        assertEq(MDualBackedFee.currentIndex(), expectedCurrentIndex);

        previousTimestamp = uint40(nextTimestamp);

        nextTimestamp = vm.getBlockTimestamp() + 365 days * 5;
        vm.warp(nextTimestamp);

        expectedCurrentIndex = _getCurrentIndex(expectedCurrentIndex, mYiedFeeEarnerRate, previousTimestamp);
        assertEq(MDualBackedFee.currentIndex(), expectedCurrentIndex);
        assertEq(MDualBackedFee.updateIndex(), expectedCurrentIndex);
    }

    function testFuzz_currentIndex(
        uint32 earnerRate,
        uint32 nextEarnerRate,
        uint16 feeRate,
        uint16 nextYieldFeeRate,
        bool isEarningEnabled,
        uint128 latestIndex,
        uint40 latestUpdateTimestamp,
        uint40 nextTimestamp,
        uint40 finalTimestamp
    ) external {
        vm.assume(nextTimestamp > latestUpdateTimestamp);

        feeRate = _setupYieldFeeRate(feeRate);

        vm.mockCall(address(mToken), abi.encodeWithSelector(IMTokenLike.earnerRate.selector), abi.encode(earnerRate));
        uint32 latestRate = MDualBackedFee.latestRate();

        MDualBackedFee.setIsEarningEnabled(isEarningEnabled);
        latestIndex = _setupLatestIndex(latestIndex);
        latestRate = _setupLatestRate(latestRate);

        vm.warp(latestUpdateTimestamp);
        MDualBackedFee.setLatestUpdateTimestamp(latestUpdateTimestamp);

        // No change in timestamp, so the index should be equal to the latest stored index
        assertEq(MDualBackedFee.currentIndex(), latestIndex);

        vm.warp(nextTimestamp);

        uint128 expectedIndex = isEarningEnabled
            ? _getCurrentIndex(latestIndex, latestRate, latestUpdateTimestamp)
            : latestIndex;

        assertEq(MDualBackedFee.currentIndex(), expectedIndex);

        vm.assume(finalTimestamp > nextTimestamp);

        // Update yield fee rate and M earner rate
        feeRate = _setupYieldFeeRate(nextYieldFeeRate);

        vm.mockCall(
            address(mToken),
            abi.encodeWithSelector(IMTokenLike.earnerRate.selector),
            abi.encode(nextEarnerRate)
        );

        latestRate = MDualBackedFee.latestRate();
        latestRate = _setupLatestRate(latestRate);

        vm.warp(finalTimestamp);

        // expectedIndex was saved as the latest index and nextTimestamp is the latest saved timestamp
        expectedIndex = isEarningEnabled ? _getCurrentIndex(expectedIndex, latestRate, nextTimestamp) : latestIndex;
        assertEq(MDualBackedFee.currentIndex(), expectedIndex);
    }

    /* ============ earnerRate ============ */

    function test_earnerRate_earningIsEnabled() external {
        uint32 mEarnerRate = 415;
        MDualBackedFee.setIsEarningEnabled(true);

        vm.mockCall(address(mToken), abi.encodeWithSelector(IMTokenLike.earnerRate.selector), abi.encode(mEarnerRate));

        assertEq(MDualBackedFee.earnerRate(), _getEarnerRate(mEarnerRate, YIELD_FEE_RATE));
    }

    function test_earnerRate_earningIsDisabled() external {
        uint32 mEarnerRate = 415;
        MDualBackedFee.setIsEarningEnabled(false);

        vm.mockCall(address(mToken), abi.encodeWithSelector(IMTokenLike.earnerRate.selector), abi.encode(mEarnerRate));

        assertEq(MDualBackedFee.earnerRate(), 0);
    }

    /* ============ _latestEarnerRateAccrualTimestamp ============ */

    function test_latestEarnerRateAccrualTimestamp() external {
        uint40 timestamp = uint40(22470340);

        vm.warp(timestamp);

        assertEq(MDualBackedFee.latestEarnerRateAccrualTimestamp(), timestamp);
    }

    /* ============ _currentEarnerRate ============ */

    function test_currentEarnerRate() external {
        uint32 earnerRate = 415;

        vm.mockCall(address(mToken), abi.encodeWithSelector(IMTokenLike.earnerRate.selector), abi.encode(earnerRate));

        assertEq(MDualBackedFee.currentEarnerRate(), earnerRate);
    }

    /* ============ accruedYieldOf ============ */

    function test_accruedYieldOf() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        MDualBackedFee.setAccountOf(alice, 500, 500); // 550 balance with yield without fee.
        assertEq(MDualBackedFee.accruedYieldOf(alice), 39); // Should be 50 - 50 * 20% = 40 but it rounds down.

        MDualBackedFee.setAccountOf(alice, 1_000, 1_000); // 1_100 balance with yield without fee.
        assertEq(MDualBackedFee.accruedYieldOf(alice), 79); // Should be 100 - 100 * 20% = 80 but it rounds down.

        // 8.5% M Yield Fee index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(MDualBackedFee.currentIndex(), 1_164738254609);

        assertEq(MDualBackedFee.accruedYieldOf(alice), 164); // Would be 210 - 210 * 20% = 168 if the index wasn't compounding.

        MDualBackedFee.setAccountOf(alice, 1_000, 1_500); // 1_885 balance with yield without fee.

        // Present balance at fee-adjusted index (1_747) - balance (1_000)
        assertEq(MDualBackedFee.accruedYieldOf(alice), 747);
    }

    function testFuzz_accruedYieldOf(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 balanceWithYield,
        uint240 balance,
        uint40 nextTimestamp,
        uint40 finalTimestamp
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (balanceWithYield, balance) = _getFuzzedBalances(
            currentIndex,
            balanceWithYield,
            balance,
            _getMaxAmount(currentIndex)
        );

        uint112 principal = _setupAccount(alice, balanceWithYield, balance);
        (, uint240 expectedYield) = _getBalanceWithYield(balance, principal, currentIndex);

        assertEq(MDualBackedFee.accruedYieldOf(alice), expectedYield);

        vm.assume(finalTimestamp > nextTimestamp);

        vm.warp(finalTimestamp);

        (, expectedYield) = _getBalanceWithYield(balance, principal, MDualBackedFee.currentIndex());
        assertEq(MDualBackedFee.accruedYieldOf(alice), expectedYield);
    }

    /* ============ balanceOf ============ */

    function test_balanceOf() external {
        uint240 balance = 1_000e6;
        MDualBackedFee.setAccountOf(alice, balance, 800e6);

        assertEq(MDualBackedFee.balanceOf(alice), balance);
    }

    /* ============ balanceWithYieldOf ============ */

    function test_balanceWithYieldOf() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        MDualBackedFee.setAccountOf(alice, 500e6, 500e6); // 550 balance with yield without fee
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 500e6 + 39_615199); // Should be 540 but it rounds down

        MDualBackedFee.setAccountOf(alice, 1_000e6, 1_000e6); // 1_100 balance with yield without fee
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000e6 + 79_230399); // Should be 1_080 but it rounds down

        // 8.5% M Yield Fee index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(MDualBackedFee.currentIndex(), 1_164738254609);

        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000e6 + 164_738254); // Would be 1_168 if the index wasn't compounding

        MDualBackedFee.setAccountOf(alice, 1_000e6, 1_500e6); // 1_885 balance with yield without fee.

        // Present balance at fee-adjusted index (1_747)
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000e6 + 747_107381);
    }

    function testFuzz_balanceWithYieldOf(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 balanceWithYield,
        uint240 balance,
        uint40 nextTimestamp,
        uint40 finalTimestamp
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (balanceWithYield, balance) = _getFuzzedBalances(
            currentIndex,
            balanceWithYield,
            balance,
            _getMaxAmount(currentIndex)
        );

        uint112 principal = _setupAccount(alice, balanceWithYield, balance);
        (, uint240 expectedYield) = _getBalanceWithYield(balance, principal, currentIndex);

        assertEq(MDualBackedFee.balanceWithYieldOf(alice), balance + expectedYield);

        vm.assume(finalTimestamp > nextTimestamp);

        vm.warp(finalTimestamp);

        (, expectedYield) = _getBalanceWithYield(balance, principal, MDualBackedFee.currentIndex());
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), balance + expectedYield);
    }

    /* ============ principalOf ============ */

    function test_principalOf() external {
        uint112 principal = 800e6;
        MDualBackedFee.setAccountOf(alice, 1_000e6, principal);

        assertEq(MDualBackedFee.principalOf(alice), principal);
    }

    /* ============ projectedTotalSupply ============ */

    function test_projectedTotalSupply() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        MDualBackedFee.setTotalPrincipal(1_000);
        MDualBackedFee.setTotalSupply(1_000);

        // Total supply + yield: 1_100
        // Yield fee: 20
        // Total supply + yield - yield fee: 1_080
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_080);
    }

    /* ============ totalAccruedYield ============ */

    function test_totalAccruedYield() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        // 550 balance with yield without fee
        MDualBackedFee.setTotalSupply(500e6);
        MDualBackedFee.setTotalPrincipal(500e6);

        assertEq(MDualBackedFee.totalAccruedYield(), 39_615199); // Should be 40 but it rounds down

        // 1_100 balance with yield without fee.
        MDualBackedFee.setTotalSupply(1_000e6);
        MDualBackedFee.setTotalPrincipal(1_000e6);
        assertEq(MDualBackedFee.totalAccruedYield(), 79_230399); // Should be 80 but it rounds down

        // 8.5% M Yield Fee index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(MDualBackedFee.currentIndex(), 1_164738254609);

        assertEq(MDualBackedFee.totalAccruedYield(), 164_738254); // Should be 168 if the index wasn't compounding

        // 1_885 balance with yield without fee
        MDualBackedFee.setTotalSupply(1_000e6);
        MDualBackedFee.setTotalPrincipal(1_500e6);

        // Present balance at fee-adjusted index (1_747) - balance (1_000)
        assertEq(MDualBackedFee.totalAccruedYield(), 747_107381);
    }

    function testFuzz_totalAccruedYield(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 totalSupplyWithYield,
        uint240 totalSupply,
        uint40 nextTimestamp,
        uint40 finalTimestamp
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (totalSupplyWithYield, totalSupply) = _getFuzzedBalances(
            currentIndex,
            totalSupplyWithYield,
            totalSupply,
            _getMaxAmount(currentIndex)
        );

        uint112 principal = _setupSupply(totalSupplyWithYield, totalSupply);
        (, uint240 expectedYield) = _getBalanceWithYield(totalSupply, principal, currentIndex);

        assertEq(MDualBackedFee.totalAccruedYield(), expectedYield);

        vm.assume(finalTimestamp > nextTimestamp);

        vm.warp(finalTimestamp);

        (, expectedYield) = _getBalanceWithYield(totalSupply, principal, MDualBackedFee.currentIndex());
        assertEq(MDualBackedFee.totalAccruedYield(), expectedYield);
    }

    /* ============ totalAccruedFee ============ */

    function test_totalAccruedFee() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        // 550 balance with yield without fee
        MDualBackedFee.setTotalSupply(500);
        MDualBackedFee.setTotalPrincipal(500);
        assertEq(MDualBackedFee.totalAccruedYield(), 39); // Should be 50 - 50 * 20% = 40 but it rounds down

        mToken.setBalanceOf(address(MDualBackedFee), 550);
        assertEq(MDualBackedFee.totalAccruedFee(), 10);
        assertEq(MDualBackedFee.totalAccruedYield() + MDualBackedFee.totalAccruedFee(), 49);

        // 1_100 balance with yield without fee.
        MDualBackedFee.setTotalSupply(1_000);
        MDualBackedFee.setTotalPrincipal(1_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 79); // Should be 100 - 100 * 20% = 80 but it rounds down

        mToken.setBalanceOf(address(MDualBackedFee), 1_100);
        assertEq(MDualBackedFee.totalAccruedFee(), 20);
        assertEq(MDualBackedFee.totalAccruedYield() + MDualBackedFee.totalAccruedFee(), 99);

        // 8.5% M Yield Fee index growth
        vm.warp(startTimestamp + 30_057_038 * 2);
        assertEq(MDualBackedFee.currentIndex(), 1_164738254609);

        assertEq(MDualBackedFee.totalAccruedYield(), 164); // Should be 210 - 210 * 20% = 168 if the index wasn't compounding

        mToken.setBalanceOf(address(MDualBackedFee), 1_210);
        assertEq(MDualBackedFee.totalAccruedFee(), 45);
        assertEq(MDualBackedFee.totalAccruedYield() + MDualBackedFee.totalAccruedFee(), 209);

        // 1_885 balance with yield without fee
        MDualBackedFee.setTotalSupply(1_000);
        MDualBackedFee.setTotalPrincipal(1_500);

        // Present balance at fee-adjusted index (1_747) - balance (1_000)
        assertEq(MDualBackedFee.totalAccruedYield(), 747);

        mToken.setBalanceOf(address(MDualBackedFee), 1_885);
        assertEq(MDualBackedFee.totalAccruedFee(), 137);
        assertEq(MDualBackedFee.totalAccruedYield() + MDualBackedFee.totalAccruedFee(), 884);
    }

    function testFuzz_totalAccruedFee(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 totalSupplyWithYield,
        uint240 totalSupply,
        uint40 nextTimestamp,
        uint40 finalTimestamp
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (totalSupplyWithYield, totalSupply) = _getFuzzedBalances(
            currentIndex,
            totalSupplyWithYield,
            totalSupply,
            _getMaxAmount(currentIndex)
        );

        uint112 principal = _setupSupply(totalSupplyWithYield, totalSupply);
        (, uint240 expectedYield) = _getBalanceWithYield(totalSupply, principal, currentIndex);
        uint256 expectedFee = _getYieldFee(expectedYield, feeRate);

        mToken.setBalanceOf(address(MDualBackedFee), totalSupply + expectedYield + expectedFee);

        assertApproxEqAbs(MDualBackedFee.totalAccruedFee(), expectedFee, 9); // May round down in favor of the protocol

        vm.assume(finalTimestamp > nextTimestamp);

        vm.warp(finalTimestamp);

        (, expectedYield) = _getBalanceWithYield(totalSupply, principal, MDualBackedFee.currentIndex());
        expectedFee = _getYieldFee(expectedYield, feeRate);

        mToken.setBalanceOf(address(MDualBackedFee), totalSupply + expectedYield + expectedFee);

        assertApproxEqAbs(MDualBackedFee.totalAccruedFee(), expectedFee, 9);
    }

    /* ============ wrap ============ */

    function test_wrap_insufficientAmount() external {
        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));

        vm.prank(address(swapFacility));
        MDualBackedFee.wrap(alice, 0);
    }

    function test_wrap_invalidRecipient() external {
        mToken.setBalanceOf(alice, 1_000);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(address(swapFacility));
        MDualBackedFee.wrap(address(0), 1_000);
    }

    function test_wrap_this() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        mToken.setBalanceOf(address(swapFacility), 1_002);
        mToken.setBalanceOf(address(MDualBackedFee), 1_100);

        MDualBackedFee.setTotalPrincipal(1_000);
        MDualBackedFee.setTotalSupply(1_000);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 20
        MDualBackedFee.setAccountOf(alice, 1_000, 1_000);

        assertEq(MDualBackedFee.principalOf(alice), 1_000);
        assertEq(MDualBackedFee.balanceOf(alice), 1_000);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 79);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000 + 79);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000);
        assertEq(MDualBackedFee.totalSupply(), 1_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 79);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_080);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 1_100);
        assertEq(MDualBackedFee.totalAccruedFee(), 20);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 999);

        vm.prank(address(swapFacility));
        MDualBackedFee.wrap(alice, 999);

        // Balance round up in favor of user, but -1 taken out of yield
        assertEq(MDualBackedFee.principalOf(alice), 1_000 + 925);
        assertEq(MDualBackedFee.balanceOf(alice), 1_000 + 999);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 78);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000 + 999 + 78);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000 + 925);
        assertEq(MDualBackedFee.totalSupply(), 1_000 + 999);
        assertEq(MDualBackedFee.totalAccruedYield(), 78);
        assertEq(MDualBackedFee.projectedTotalSupply(), 2078);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 2_099);
        assertEq(MDualBackedFee.totalAccruedFee(), 21);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 1);

        vm.prank(address(swapFacility));
        MDualBackedFee.wrap(alice, 1);

        assertEq(MDualBackedFee.principalOf(alice), 1_000 + 925); // No change due to principal round down on wrap.
        assertEq(MDualBackedFee.balanceOf(alice), 1_000 + 999 + 1);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 78 - 1);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000 + 999 + 78);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000 + 925);
        assertEq(MDualBackedFee.totalSupply(), 1_000 + 999 + 1);
        assertEq(MDualBackedFee.totalAccruedYield(), 77);
        assertEq(MDualBackedFee.projectedTotalSupply(), 2_078);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 2_100);
        assertEq(MDualBackedFee.totalAccruedFee(), 22);

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, 2);

        vm.prank(address(swapFacility));
        MDualBackedFee.wrap(alice, 2);

        assertEq(MDualBackedFee.principalOf(alice), 1_000 + 926);
        assertEq(MDualBackedFee.balanceOf(alice), 1_000 + 999 + 1 + 2);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000 + 999 + 78 + 1);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 78 - 1 - 1);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000 + 926);
        assertEq(MDualBackedFee.totalSupply(), 1_000 + 999 + 1 + 2);
        assertEq(MDualBackedFee.totalAccruedYield(), 76);
        assertEq(MDualBackedFee.projectedTotalSupply(), 2_079);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 2_099 + 1 + 2);
    }

    function testFuzz_wrap(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 balanceWithYield,
        uint240 balance,
        uint240 wrapAmount
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (balanceWithYield, balance) = _getFuzzedBalances(
            currentIndex,
            balanceWithYield,
            balance,
            _getMaxAmount(currentIndex)
        );

        _setupAccount(alice, balanceWithYield, balance);
        wrapAmount = uint240(bound(wrapAmount, 0, _getMaxAmount(currentIndex) - balanceWithYield));

        mToken.setBalanceOf(address(swapFacility), wrapAmount);

        if (wrapAmount == 0) {
            vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, (0)));
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(address(0), alice, wrapAmount);
        }

        vm.prank(address(swapFacility));
        MDualBackedFee.wrap(alice, wrapAmount);

        if (wrapAmount == 0) return;

        balance += wrapAmount;

        // When wrapping, added principal for account is always rounded down in favor of the protocol.
        // So in our test we need to round down too to accurately calculate balanceWithYield.
        balanceWithYield = IndexingMath.getPresentAmountRoundedDown(
            IndexingMath.getPrincipalAmountRoundedDown(balanceWithYield, currentIndex) +
                IndexingMath.getPrincipalAmountRoundedDown(wrapAmount, currentIndex),
            currentIndex
        );

        uint256 aliceYield = balanceWithYield <= balance ? 0 : balanceWithYield - balance;
        uint256 yieldFee = _getYieldFee(aliceYield, feeRate);

        assertEq(MDualBackedFee.balanceOf(alice), balance);
        assertEq(MDualBackedFee.balanceOf(alice), MDualBackedFee.totalSupply());

        // Rounds down on wrap for alice and up for total principal.
        assertApproxEqAbs(MDualBackedFee.principalOf(alice), MDualBackedFee.totalPrincipal(), 1);

        assertEq(MDualBackedFee.balanceWithYieldOf(alice), balance + aliceYield);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), balance + MDualBackedFee.accruedYieldOf(alice));

        // Simulate M token balance.
        mToken.setBalanceOf(address(MDualBackedFee), balance + aliceYield + yieldFee);

        // May round down in favor of the protocol
        assertApproxEqAbs(MDualBackedFee.balanceWithYieldOf(alice), MDualBackedFee.projectedTotalSupply(), 17);
        assertEq(MDualBackedFee.totalAccruedYield(), aliceYield);
        assertApproxEqAbs(MDualBackedFee.totalAccruedFee(), yieldFee, 17);
    }

    /* ============ wrap secondary ============ */

    function test_wrap_secondary() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        mToken.setBalanceOf(address(swapFacility), 1_000_002);
        mToken.setBalanceOf(address(MDualBackedFee), 1_100_000);
        SECONDARY.mint(address(swapFacility), 1_000_000);

        MDualBackedFee.setTotalPrincipal(1_000_000);
        MDualBackedFee.setTotalSupply(1_000_000);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 20
        MDualBackedFee.setAccountOf(alice, 1_000_000, 1_000_000);

        assertEq(MDualBackedFee.principalOf(alice), 1_000_000);
        assertEq(MDualBackedFee.balanceOf(alice), 1_000_000);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 79_230);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000_000 + 79_230);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000_000);
        assertEq(MDualBackedFee.totalSupply(), 1_000_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 79_230);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_079_231);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 1_100_000);
        assertEq(MDualBackedFee.totalAccruedFee(), 20_769);

        vm.prank(address(swapFacility));
        SECONDARY.approve(address(MDualBackedFee), type(uint256).max);

        vm.prank(address(swapFacility));
        MDualBackedFee.wrapSecondary(alice, 1_000_000);

        assertEq(MDualBackedFee.secondaryIndex(), 5e11);

        assertEq(MDualBackedFee.principalOf(alice), 1_000_000);
        assertEq(MDualBackedFee.balanceOf(alice), 2_000_000);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 79_230);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 2_000_000 + 79_230);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000_000);
        assertEq(MDualBackedFee.totalSupply(), 2_000_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 79_230);
        assertEq(MDualBackedFee.projectedTotalSupply(), 2_079_231);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 1_100_000);
        assertEq(MDualBackedFee.totalAccruedFee(), 20_769);

        // Check that claiming yield adjusts secondary
        // index to indicate more backing from M
        MDualBackedFee.claimYieldFor(alice);

        assertEq(MDualBackedFee.secondaryIndex(), 519052726249);

        assertEq(MDualBackedFee.principalOf(alice), 1_000_000);
        assertEq(MDualBackedFee.balanceOf(alice), 2_079_230);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 1);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 2_079_231);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000_000);
        assertEq(MDualBackedFee.totalSupply(), 2_079_230);
        assertEq(MDualBackedFee.totalAccruedYield(), 0);
        assertEq(MDualBackedFee.projectedTotalSupply(), 2_079_231);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 1_100_000);
        assertEq(MDualBackedFee.totalAccruedFee(), 20_769);

        // Check that claming fee adjusts secondary
        // index to indicate more backing from M
        uint256 yieldFee_ = MDualBackedFee.claimFee();

        assertEq(MDualBackedFee.principalOf(feeRecipient), 9989);
        assertEq(MDualBackedFee.balanceOf(feeRecipient), 20_769);
        assertEq(MDualBackedFee.accruedYieldOf(feeRecipient), 0);
        assertEq(MDualBackedFee.balanceWithYieldOf(feeRecipient), 20_769);

        // assertEq(MDualBackedFee.balanceWithYieldOf(alice), 2_079_231);
        // assertEq(MDualBackedFee.balanceOf(alice), 2_079_230);

        // assertEq(MDualBackedFee.totalPrincipal(), 1_009_989);
        // assertEq(MDualBackedFee.totalSupply(), 2_079_230 + 20_769);

        // console.log("current index", MDualBackedFee.currentIndex());
        // assertEq(MDualBackedFee.totalAccruedFee(), 0);
    }

    function test_secondary_claim_fee() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        vm.prank(feeManager);
        MDualBackedFee.setFeeRate(5_000);

        // 10% M token index growth, 5% M Yield Fee index growth because of the 50% fee.
        vm.warp(startTimestamp + 30_772_933);
        assertEq(MDualBackedFee.currentIndex(), 1050000001090);

        mToken.setBalanceOf(address(swapFacility), 1_000_002);
        mToken.setBalanceOf(address(MDualBackedFee), 1_100_000);
        SECONDARY.mint(address(swapFacility), 1_000_000);

        MDualBackedFee.setTotalPrincipal(1_000_000);
        MDualBackedFee.setTotalSupply(1_000_000);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_050
        // Fee: 50
        MDualBackedFee.setAccountOf(alice, 1_000_000, 1_000_000);

        assertEq(MDualBackedFee.principalOf(alice), 1_000_000);
        assertEq(MDualBackedFee.balanceOf(alice), 1_000_000);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 50_000);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 1_000_000 + 50_000);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000_000);
        assertEq(MDualBackedFee.totalSupply(), 1_000_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 50_000);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_050_001);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 1_100_000);
        assertEq(MDualBackedFee.totalAccruedFee(), 49_999);

        vm.prank(address(swapFacility));
        SECONDARY.approve(address(MDualBackedFee), type(uint256).max);

        vm.prank(address(swapFacility));
        MDualBackedFee.wrapSecondary(alice, 1_000_000);

        assertEq(MDualBackedFee.secondaryIndex(), 5e11);

        assertEq(MDualBackedFee.principalOf(alice), 1_000_000);
        assertEq(MDualBackedFee.balanceOf(alice), 2_000_000);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 50_000);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), 2_000_000 + 50_000);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000_000);
        assertEq(MDualBackedFee.totalSupply(), 2_000_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 50_000);
        assertEq(MDualBackedFee.projectedTotalSupply(), 2_050_001);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 1_100_000);
        assertEq(MDualBackedFee.totalAccruedFee(), 49_999);

        // Check that claming fee adjusts secondary
        // index to indicate more backing from M
        uint256 yieldFee_ = MDualBackedFee.claimFee();

        assertEq(MDualBackedFee.principalOf(feeRecipient), 47_619, "principal of fr");
        assertEq(MDualBackedFee.balanceOf(feeRecipient), 49_999, "balance of fr");
        assertEq(MDualBackedFee.accruedYieldOf(feeRecipient), 0, "accrued yield of fr");
        assertEq(MDualBackedFee.balanceWithYieldOf(feeRecipient), 49_999, "balance with yield of fr");

        // assertEq(MDualBackedFee.balanceWithYieldOf(alice), 2_050_001, "balance with yield of a");
        // assertEq(MDualBackedFee.balanceOf(alice), 2_000_000, "balance of a");

        // assertEq(MDualBackedFee.totalPrincipal(), 1_023_809, "total p");
        // assertEq(MDualBackedFee.totalSupply(), 2_000_000 + 49_999, "total s");

        // console.log("current index", MDualBackedFee.currentIndex());
        // assertEq(MDualBackedFee.totalAccruedFee(), 0);
    }

    /* ============ unwrap ============ */

    // function test_unwrap_insufficientAmount() external {
    //     vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, 0));
    //
    //     vm.prank(address(swapFacility));
    //     MDualBackedFee.unwrap(alice, 0);
    // }
    //
    // function test_unwrap_insufficientBalance() external {
    //     MDualBackedFee.setAccountOf(address(swapFacility), 999, 909);
    //
    //     vm.prank(alice);
    //     IERC20(address(MDualBackedFee)).approve(address(swapFacility), 1_000);
    //
    //     vm.expectRevert(
    //         abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, address(swapFacility), 999, 1_000)
    //     );
    //
    //     vm.prank(address(swapFacility));
    //     MDualBackedFee.unwrap(alice, 1_000);
    // }

    function test_unwrap() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        mToken.setBalanceOf(address(MDualBackedFee), 1_100);

        MDualBackedFee.setTotalPrincipal(1_000);
        MDualBackedFee.setTotalSupply(1_000);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 21
        MDualBackedFee.setAccountOf(address(swapFacility), 1_000, 1_000); // 1_100 balance with yield without fee

        assertEq(MDualBackedFee.principalOf(address(swapFacility)), 1_000);
        assertEq(MDualBackedFee.balanceOf(address(swapFacility)), 1_000);
        assertEq(MDualBackedFee.accruedYieldOf(address(swapFacility)), 79);
        assertEq(MDualBackedFee.balanceWithYieldOf(address(swapFacility)), 1_000 + 79);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000);
        assertEq(MDualBackedFee.totalSupply(), 1_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 79);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_080);

        vm.prank(alice);
        MDualBackedFee.approve(address(swapFacility), 1_000);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1);

        vm.prank(address(swapFacility));
        MDualBackedFee.unwrap(alice, 1);

        assertEq(MDualBackedFee.principalOf(address(swapFacility)), 1_000 - 1);
        assertEq(MDualBackedFee.balanceOf(address(swapFacility)), 1_000 - 1);
        assertEq(MDualBackedFee.accruedYieldOf(address(swapFacility)), 79);
        assertEq(MDualBackedFee.balanceWithYieldOf(address(swapFacility)), 1_000 + 79 - 1);
        assertEq(MDualBackedFee.totalPrincipal(), 999);
        assertEq(MDualBackedFee.totalSupply(), 1_000 - 1);
        assertEq(MDualBackedFee.totalAccruedYield(), 79);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_079);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499);

        vm.prank(address(swapFacility));
        MDualBackedFee.unwrap(alice, 499);

        assertEq(MDualBackedFee.principalOf(address(swapFacility)), 1_000 - 1 - 463);
        assertEq(MDualBackedFee.balanceOf(address(swapFacility)), 1_000 - 1 - 499);
        assertEq(MDualBackedFee.accruedYieldOf(address(swapFacility)), 79 - 1);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000 - 463 - 1);
        assertEq(MDualBackedFee.totalSupply(), 1_000 - 1 - 499);
        assertEq(MDualBackedFee.totalAccruedYield(), 78);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_080 - 499 - 2);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500);

        vm.prank(address(swapFacility));
        MDualBackedFee.unwrap(alice, 500);

        assertEq(MDualBackedFee.principalOf(address(swapFacility)), 1_000 - 1 - 463 - 464); // 72
        assertEq(MDualBackedFee.balanceOf(address(swapFacility)), 1_000 - 1 - 499 - 500); // 0
        assertEq(MDualBackedFee.accruedYieldOf(address(swapFacility)), 77);
        assertEq(MDualBackedFee.totalPrincipal(), 1_000 - 464 - 463 - 1); // 72
        assertEq(MDualBackedFee.totalSupply(), 1_000 - 1 - 499 - 500); // 0
        assertEq(MDualBackedFee.totalAccruedYield(), 77);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_080 - 499 - 500 - 3);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), 1000);
        assertEq(mToken.balanceOf(address(MDualBackedFee)), 100);
        assertEq(mToken.balanceOf(alice), 0);
    }

    function testFuzz_unwrap(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 balanceWithYield,
        uint240 balance,
        uint240 unwrapAmount
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (balanceWithYield, balance) = _getFuzzedBalances(
            currentIndex,
            balanceWithYield,
            balance,
            _getMaxAmount(currentIndex)
        );

        _setupAccount(address(swapFacility), balanceWithYield, balance);
        unwrapAmount = uint240(bound(unwrapAmount, 0, _getMaxAmount(currentIndex) - balanceWithYield));

        mToken.setBalanceOf(address(MDualBackedFee), balanceWithYield);

        vm.prank(alice);
        MDualBackedFee.approve(address(swapFacility), unwrapAmount);

        if (unwrapAmount == 0) {
            vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InsufficientAmount.selector, (0)));
        } else if (unwrapAmount > balance) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IMExtension.InsufficientBalance.selector,
                    address(swapFacility),
                    balance,
                    unwrapAmount
                )
            );
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(address(swapFacility), address(0), unwrapAmount);
        }

        vm.prank(address(swapFacility));
        MDualBackedFee.unwrap(alice, unwrapAmount);

        if ((unwrapAmount == 0) || (unwrapAmount > balance)) return;

        balance -= unwrapAmount;

        uint112 balanceWithYieldPrincipal = IndexingMath.getPrincipalAmountRoundedDown(balanceWithYield, currentIndex);

        // When unwrapping, subtracted principal for account is always rounded up in favor of the protocol.
        // So in our test we need to round up too to accurately calculate balanceWithYield.
        balanceWithYield = IndexingMath.getPresentAmountRoundedDown(
            balanceWithYieldPrincipal -
                UIntMath.min112(
                    IndexingMath.getPrincipalAmountRoundedUp(unwrapAmount, currentIndex),
                    balanceWithYieldPrincipal
                ),
            currentIndex
        );

        uint256 aliceYield = (balanceWithYield <= balance) ? 0 : balanceWithYield - balance;
        uint256 yieldFee = _getYieldFee(aliceYield, feeRate);

        assertEq(MDualBackedFee.balanceOf(address(swapFacility)), balance);
        assertEq(MDualBackedFee.balanceOf(address(swapFacility)), MDualBackedFee.totalSupply());

        // Rounds up on unwrap for alice and down for total principal.
        assertApproxEqAbs(MDualBackedFee.principalOf(address(swapFacility)), MDualBackedFee.totalPrincipal(), 1);

        assertEq(MDualBackedFee.balanceWithYieldOf(address(swapFacility)), balance + aliceYield);
        assertEq(
            MDualBackedFee.balanceWithYieldOf(address(swapFacility)),
            balance + MDualBackedFee.accruedYieldOf(address(swapFacility))
        );

        // Simulate M token balance.
        mToken.setBalanceOf(address(MDualBackedFee), balance + aliceYield + yieldFee);

        assertApproxEqAbs(
            MDualBackedFee.balanceWithYieldOf(address(swapFacility)),
            MDualBackedFee.projectedTotalSupply(),
            15
        );
        assertEq(MDualBackedFee.totalAccruedYield(), aliceYield);
        assertApproxEqAbs(MDualBackedFee.totalAccruedFee(), yieldFee, 15);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), unwrapAmount);
        assertEq(mToken.balanceOf(alice), 0);
    }

    /* ============ transfer ============ */

    function test_transfer_invalidRecipient() external {
        MDualBackedFee.setAccountOf(alice, 1_000, 1_000);

        vm.expectRevert(abi.encodeWithSelector(IERC20Extended.InvalidRecipient.selector, address(0)));

        vm.prank(alice);
        MDualBackedFee.transfer(address(0), 1_000);
    }

    function test_transfer_insufficientBalance_toSelf() external {
        MDualBackedFee.setAccountOf(alice, 999, 999);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        MDualBackedFee.transfer(alice, 1_000);
    }

    function test_transfer_insufficientBalance() external {
        MDualBackedFee.setAccountOf(alice, 999, 999);

        vm.expectRevert(abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, 999, 1_000));

        vm.prank(alice);
        MDualBackedFee.transfer(bob, 1_000);
    }

    function test_transfer() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        mToken.setBalanceOf(alice, 1_002);
        mToken.setBalanceOf(address(MDualBackedFee), 1_500);

        MDualBackedFee.setTotalPrincipal(1_500);
        MDualBackedFee.setTotalSupply(1_500);

        // Total supply + yield: 1_100
        // Alice balance with yield: 1_079
        // Fee: 21
        MDualBackedFee.setAccountOf(alice, 1_000, 1_000);

        // Bob balance with yield: 539
        // Balance: 500
        // Yield: 50
        // Fee: 11
        MDualBackedFee.setAccountOf(bob, 500, 500);

        assertEq(MDualBackedFee.accruedYieldOf(alice), 79);
        assertEq(MDualBackedFee.accruedYieldOf(bob), 39);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, 500);

        vm.prank(alice);
        MDualBackedFee.transfer(bob, 500);

        assertEq(MDualBackedFee.principalOf(alice), 536);
        assertEq(MDualBackedFee.balanceOf(alice), 500);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 78);

        assertEq(MDualBackedFee.principalOf(bob), 964);
        assertEq(MDualBackedFee.balanceOf(bob), 1_000);
        assertEq(MDualBackedFee.accruedYieldOf(bob), 40);

        assertEq(MDualBackedFee.totalSupply(), 1_500);

        // Principal is rounded up when adding and rounded down when subtracting.
        assertEq(MDualBackedFee.totalPrincipal(), 1_500);
        assertEq(MDualBackedFee.totalAccruedYield(), 79 + 39);
    }

    function test_transfer_toSelf() external {
        MDualBackedFee.setIsEarningEnabled(true);
        MDualBackedFee.setLatestRate(mYiedFeeEarnerRate);

        // 10% M token index growth, 7.9% M Yield Fee index growth because of the 20% fee.
        vm.warp(startTimestamp + 30_057_038);
        assertEq(MDualBackedFee.currentIndex(), 1_079230399224);

        MDualBackedFee.setTotalPrincipal(1_000);
        MDualBackedFee.setTotalSupply(1_000);
        mToken.setBalanceOf(address(MDualBackedFee), 1_125);

        // Total supply + yield: 1_125
        // Alice balance with yield: 1_100
        // Fee: 21
        MDualBackedFee.setAccountOf(alice, 1_000, 1_000);

        assertEq(MDualBackedFee.balanceOf(alice), 1_000);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 79);

        vm.expectEmit();
        emit IERC20.Transfer(alice, alice, 500);

        vm.prank(alice);
        MDualBackedFee.transfer(alice, 500);

        assertEq(MDualBackedFee.principalOf(alice), 1_000);
        assertEq(MDualBackedFee.balanceOf(alice), 1_000);
        assertEq(MDualBackedFee.accruedYieldOf(alice), 79);

        assertEq(MDualBackedFee.totalPrincipal(), 1_000);
        assertEq(MDualBackedFee.totalSupply(), 1_000);
        assertEq(MDualBackedFee.totalAccruedYield(), 79);
        assertEq(MDualBackedFee.projectedTotalSupply(), 1_080);
    }

    function testFuzz_transfer(
        bool earningEnabled,
        uint16 feeRate,
        uint128 latestIndex,
        uint240 aliceBalanceWithYield,
        uint240 aliceBalance,
        uint240 bobBalanceWithYield,
        uint240 bobBalance,
        uint240 amount
    ) external {
        _setupYieldFeeRate(feeRate);

        uint128 currentIndex = _setupIndex(earningEnabled, latestIndex);
        (aliceBalanceWithYield, aliceBalance) = _getFuzzedBalances(
            currentIndex,
            aliceBalanceWithYield,
            aliceBalance,
            _getMaxAmount(currentIndex)
        );

        (bobBalanceWithYield, bobBalance) = _getFuzzedBalances(
            currentIndex,
            bobBalanceWithYield,
            bobBalance,
            _getMaxAmount(currentIndex) - aliceBalanceWithYield
        );

        _setupAccount(alice, aliceBalanceWithYield, aliceBalance);
        _setupAccount(bob, bobBalanceWithYield, bobBalance);

        amount = uint240(bound(amount, 0, _getMaxAmount(currentIndex) - bobBalanceWithYield));

        if (amount > aliceBalance) {
            vm.expectRevert(
                abi.encodeWithSelector(IMExtension.InsufficientBalance.selector, alice, aliceBalance, amount)
            );
        } else {
            vm.expectEmit();
            emit IERC20.Transfer(alice, bob, amount);
        }

        vm.prank(alice);
        MDualBackedFee.transfer(bob, amount);

        if (amount > aliceBalance) return;

        aliceBalance -= amount;
        bobBalance += amount;

        assertEq(MDualBackedFee.balanceOf(alice), aliceBalance);
        assertEq(MDualBackedFee.balanceOf(bob), bobBalance);
        assertEq(MDualBackedFee.totalSupply(), aliceBalance + bobBalance);
        assertEq(MDualBackedFee.totalSupply(), MDualBackedFee.balanceOf(alice) + MDualBackedFee.balanceOf(bob));

        uint112 aliceBalanceWithYieldPrincipal = IndexingMath.getPrincipalAmountRoundedDown(
            aliceBalanceWithYield,
            currentIndex
        );

        aliceBalanceWithYieldPrincipal =
            aliceBalanceWithYieldPrincipal -
            UIntMath.min112(
                IndexingMath.getPrincipalAmountRoundedUp(amount, currentIndex),
                aliceBalanceWithYieldPrincipal
            );

        // When subtracting, subtracted principal for account is always rounded up in favor of the protocol.
        // So in our test we need to round up too to accurately calculate aliceBalanceWithYield.
        aliceBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(aliceBalanceWithYieldPrincipal, currentIndex);

        uint112 bobBalanceWithYieldPrincipal = IndexingMath.getPrincipalAmountRoundedDown(
            bobBalanceWithYield,
            currentIndex
        ) + IndexingMath.getPrincipalAmountRoundedDown(amount, currentIndex);

        // When adding, added principal for account is always rounded down in favor of the protocol.
        // So in our test we need to round down too to accurately calculate bobBalanceWithYield.
        bobBalanceWithYield = IndexingMath.getPresentAmountRoundedDown(bobBalanceWithYieldPrincipal, currentIndex);

        uint240 aliceYield = aliceBalanceWithYield <= aliceBalance ? 0 : aliceBalanceWithYield - aliceBalance;
        uint240 bobYield = bobBalanceWithYield <= bobBalance ? 0 : bobBalanceWithYield - bobBalance;
        uint256 yieldFee = _getYieldFee(aliceYield + bobYield, feeRate);

        assertEq(MDualBackedFee.balanceWithYieldOf(alice), aliceBalance + aliceYield);
        assertEq(MDualBackedFee.balanceWithYieldOf(alice), aliceBalance + MDualBackedFee.accruedYieldOf(alice));

        // Bob may gain more due to rounding.
        assertApproxEqAbs(MDualBackedFee.balanceWithYieldOf(bob), bobBalance + bobYield, 10);
        assertEq(MDualBackedFee.balanceWithYieldOf(bob), bobBalance + MDualBackedFee.accruedYieldOf(bob));

        // Principal added or removed from totalPrincipal is rounded up when adding and rounded down when subtracting.
        assertApproxEqAbs(
            MDualBackedFee.totalPrincipal(),
            aliceBalanceWithYieldPrincipal + bobBalanceWithYieldPrincipal,
            2
        );
        assertApproxEqAbs(
            MDualBackedFee.totalPrincipal(),
            MDualBackedFee.principalOf(alice) + MDualBackedFee.principalOf(bob),
            2
        );

        uint256 mBalance = aliceBalance + aliceYield + bobBalance + bobYield + yieldFee;

        // Simulate M token balance.
        mToken.setBalanceOf(address(MDualBackedFee), mBalance);

        // projectedTotalSupply rounds up in favor of the protocol
        assertApproxEqAbs(
            MDualBackedFee.projectedTotalSupply(),
            MDualBackedFee.balanceWithYieldOf(alice) + MDualBackedFee.balanceWithYieldOf(bob),
            16
        );

        assertApproxEqAbs(MDualBackedFee.totalAccruedFee(), yieldFee, 16);
    }

    /* ============ currentIndex Utils ============ */

    function _getCurrentIndex(
        uint128 latestIndex,
        uint32 latestRate,
        uint40 latestUpdateTimestamp
    ) internal view returns (uint128) {
        return
            UIntMath.bound128(
                ContinuousIndexingMath.multiplyIndicesDown(
                    latestIndex,
                    ContinuousIndexingMath.getContinuousIndex(
                        ContinuousIndexingMath.convertFromBasisPoints(latestRate),
                        uint32(MDualBackedFee.latestEarnerRateAccrualTimestamp() - latestUpdateTimestamp)
                    )
                )
            );
    }

    /* ============ Fuzz Utils ============ */

    function _setupAccount(
        address account,
        uint240 balanceWithYield,
        uint240 balance
    ) internal returns (uint112 principal_) {
        principal_ = IndexingMath.getPrincipalAmountRoundedDown(balanceWithYield, MDualBackedFee.currentIndex());

        MDualBackedFee.setAccountOf(account, balance, principal_);
        MDualBackedFee.setTotalPrincipal(MDualBackedFee.totalPrincipal() + principal_);
        MDualBackedFee.setTotalSupply(MDualBackedFee.totalSupply() + balance);
    }

    function _setupSupply(uint240 totalSupplyWithYield, uint240 totalSupply) internal returns (uint112 principal_) {
        principal_ = IndexingMath.getPrincipalAmountRoundedDown(totalSupplyWithYield, MDualBackedFee.currentIndex());

        MDualBackedFee.setTotalPrincipal(MDualBackedFee.totalPrincipal() + principal_);
        MDualBackedFee.setTotalSupply(MDualBackedFee.totalSupply() + totalSupply);
    }

    function _setupYieldFeeRate(uint16 rate) internal returns (uint16) {
        rate = uint16(bound(rate, 0, ONE_HUNDRED_PERCENT));

        vm.prank(feeManager);
        MDualBackedFee.setFeeRate(rate);

        return rate;
    }

    function _setupLatestRate(uint32 rate) internal returns (uint32) {
        rate = uint32(bound(rate, 10, 10_000));
        MDualBackedFee.setLatestRate(rate);
        return rate;
    }

    function _setupLatestIndex(uint128 latestIndex) internal returns (uint128) {
        latestIndex = uint128(bound(latestIndex, EXP_SCALED_ONE, 10_000000000000));
        MDualBackedFee.setLatestIndex(latestIndex);
        return latestIndex;
    }

    function _setupIndex(bool earningEnabled, uint128 latestIndex) internal returns (uint128) {
        MDualBackedFee.setLatestIndex(bound(latestIndex, EXP_SCALED_ONE, 10_000000000000));

        if (earningEnabled) {
            MDualBackedFee.setIsEarningEnabled(true);
        } else {
            MDualBackedFee.setIsEarningEnabled(false);
        }

        return MDualBackedFee.currentIndex();
    }
}
