// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import {
    Initializable
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { Upgrades, UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IMExtension } from "../../src/interfaces/IMExtension.sol";

import { MExtensionHarness } from "../harness/MExtensionHarness.sol";

import { BaseUnitTest } from "../utils/BaseUnitTest.sol";

contract MExtensionUnitTests is BaseUnitTest {
    MExtensionHarness public mExtension;

    string public constant NAME = "M Extension";
    string public constant SYMBOL = "ME";

    function setUp() public override {
        super.setUp();

        mExtension = MExtensionHarness(
            Upgrades.deployUUPSProxy(
                "MExtensionHarness.sol:MExtensionHarness",
                abi.encodeWithSelector(
                    MExtensionHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(mToken),
                    address(swapFacility)
                )
            )
        );
    }

    /* ============ initialize ============ */

    function test_initialize() external {
        assertEq(mExtension.name(), NAME);
        assertEq(mExtension.symbol(), SYMBOL);
        assertEq(mExtension.decimals(), 6);
        assertEq(mExtension.mToken(), address(mToken));
        assertEq(mExtension.swapFacility(), address(swapFacility));
    }

    function test_initialize_zeroMToken() external {
        address implementation = address(new MExtensionHarness());

        vm.expectRevert(IMExtension.ZeroMToken.selector);
        MExtensionHarness(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    MExtensionHarness.initialize.selector,
                    NAME,
                    SYMBOL,
                    address(0),
                    address(swapFacility)
                )
            )
        );
    }

    function test_initialize_zeroSwapFacility() external {
        address implementation = address(new MExtensionHarness());

        vm.expectRevert(IMExtension.ZeroSwapFacility.selector);
        MExtensionHarness(
            UnsafeUpgrades.deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(MExtensionHarness.initialize.selector, NAME, SYMBOL, address(mToken), address(0))
            )
        );
    }

    /* ============ upgrade ============ */

    function test_initializerDisabled() external {
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        vm.prank(alice);
        MExtensionHarness(Upgrades.getImplementationAddress(address(mExtension))).initialize(
            NAME,
            SYMBOL,
            address(mToken),
            address(swapFacility)
        );
    }
}
