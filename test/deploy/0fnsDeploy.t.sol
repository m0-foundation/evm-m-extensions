// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { IERC20 } from "../../lib/forge-std/src/interfaces/IERC20.sol";

import {
    IAccessControl
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { Deploy0fnsBase } from "../../script/deploy/vendor/Dfns/Deploy0fnsBase.sol";

import { IMEarnerManager } from "../../src/projects/earnerManager/IMEarnerManager.sol";

import { IMExtension } from "../../src/interfaces/IMExtension.sol";

import { MExtensionUpgrade } from "../utils/Mocks.sol";

contract Deploy0fnsTests is Deploy0fnsBase, Test {
    uint256 public mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"), 23535885); // Block before 0fns deployment
    }

    /* ============ Deploy ============ */

    function testFork_deployEthereumMainnet() external {
        vm.selectFork(mainnetFork);

        vm.deal(DEPLOYER, 100 ether);

        vm.startPrank(DEPLOYER);

        (, address proxy, ) = _deploy0fns(
            DEPLOYER,
            M_TOKEN,
            SWAP_FACILITY,
            NAME,
            SYMBOL,
            ADMIN,
            EARNER_MANAGER,
            FEE_RECIPIENT
        );

        vm.stopPrank();

        assertEq(proxy, _getCreate3Address(DEPLOYER, _computeSalt(DEPLOYER, "EarnerEpsilon")));

        assertEq(IERC20(proxy).name(), NAME);
        assertEq(IERC20(proxy).symbol(), SYMBOL);

        assertEq(IMExtension(proxy).mToken(), M_TOKEN);
        assertEq(IMExtension(proxy).swapFacility(), SWAP_FACILITY);

        assertTrue(IAccessControl(proxy).hasRole(0x00, ADMIN));
        assertTrue(IAccessControl(proxy).hasRole(keccak256("EARNER_MANAGER_ROLE"), EARNER_MANAGER));
        assertEq(IMEarnerManager(proxy).feeRecipient(), FEE_RECIPIENT);
    }

    /* ============ Upgrade ============ */

    function testFork_upgradeEthereumMainnet() external {
        vm.selectFork(mainnetFork);

        vm.deal(DEPLOYER, 100 ether);

        (, address proxy, ) = _deploy0fns(
            DEPLOYER,
            M_TOKEN,
            SWAP_FACILITY,
            NAME,
            SYMBOL,
            ADMIN,
            EARNER_MANAGER,
            FEE_RECIPIENT
        );

        UnsafeUpgrades.upgradeProxy(proxy, address(new MExtensionUpgrade()), "", ADMIN);

        assertEq(MExtensionUpgrade(proxy).bar(), 1);
    }
}
