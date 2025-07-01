// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import {
    IAccessControl
} from "../../../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { Upgrades, UnsafeUpgrades } from "../../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MYieldFee } from "../../../../src/projects/yieldToAllWithFee/MYieldFee.sol";
import { IContinuousIndexing } from "../../../../src/projects/yieldToAllWithFee/interfaces/IContinuousIndexing.sol";
import { IRateOracle } from "../../../../src/projects/yieldToAllWithFee/interfaces/IRateOracle.sol";
import { IMSpokeYieldFee } from "../../../../src/projects/yieldToAllWithFee/interfaces/IMSpokeYieldFee.sol";

import { MSpokeYieldFeeHarness } from "../../../harness/MSpokeYieldFeeHarness.sol";
import { BaseUnitTest } from "../../../utils/BaseUnitTest.sol";
import { MExtensionUpgrade } from "../../../utils/Mocks.sol";

contract MSpokeYieldFeeUnitTests is BaseUnitTest {
    MSpokeYieldFeeHarness public mYieldFee;

    function setUp() public override {
        super.setUp();

        mYieldFee = MSpokeYieldFeeHarness(
            Upgrades.deployUUPSProxy(
                "MSpokeYieldFeeHarness.sol:MSpokeYieldFeeHarness",
                abi.encodeWithSelector(
                    MSpokeYieldFeeHarness.initialize.selector,
                    MYieldFee.MYieldFeeInitParams({
                        name: "MSpokeYieldFee",
                        symbol: "MSYF",
                        mToken: address(mToken),
                        swapFacility: address(swapFacility),
                        feeRate: YIELD_FEE_RATE,
                        feeRecipient: feeRecipient,
                        admin: admin,
                        feeManager: yieldFeeManager,
                        claimRecipientManager: claimRecipientManager,
                        upgrader: upgrader
                    }),
                    address(rateOracle)
                )
            )
        );
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertEq(mYieldFee.rateOracle(), address(rateOracle));
    }

    function test_initialize_zeroRateOracle() external {
        address implementation = address(new MSpokeYieldFeeHarness());

        vm.expectRevert(IMSpokeYieldFee.ZeroRateOracle.selector);
        MSpokeYieldFeeHarness(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    MSpokeYieldFeeHarness.initialize.selector,
                    MYieldFee.MYieldFeeInitParams({
                        name: "MSpokeYieldFee",
                        symbol: "MSYF",
                        mToken: address(mToken),
                        swapFacility: address(swapFacility),
                        feeRate: YIELD_FEE_RATE,
                        feeRecipient: feeRecipient,
                        admin: admin,
                        feeManager: yieldFeeManager,
                        claimRecipientManager: claimRecipientManager,
                        upgrader: upgrader
                    }),
                    address(0)
                )
            )
        );
    }

    /* ============ _currentBlockTimestamp ============ */

    function test_currentBlockTimestamp() external {
        uint40 timestamp = uint40(22470340);

        vm.mockCall(
            address(mToken),
            abi.encodeWithSelector(IContinuousIndexing.latestUpdateTimestamp.selector),
            abi.encode(timestamp)
        );

        assertEq(mYieldFee.currentBlockTimestamp(), timestamp);
    }

    /* ============ _currentEarnerRate ============ */

    function test_currentEarnerRate() external {
        uint32 earnerRate = 415;

        vm.mockCall(
            address(rateOracle),
            abi.encodeWithSelector(IRateOracle.earnerRate.selector),
            abi.encode(earnerRate)
        );

        assertEq(mYieldFee.currentEarnerRate(), earnerRate);
    }

    /* ============ upgrade ============ */

    function test_upgrade_onlyUpgrader() external {
        address v2implementation = address(new MExtensionUpgrade());

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, UPGRADER_ROLE)
        );

        vm.prank(alice);
        mYieldFee.upgradeToAndCall(v2implementation, "");
    }

    function test_upgrade() public {
        address v2implementation = address(new MExtensionUpgrade());

        vm.prank(upgrader);
        mYieldFee.upgradeToAndCall(v2implementation, "");

        assertEq(MExtensionUpgrade(address(mYieldFee)).bar(), 1);
    }
}
