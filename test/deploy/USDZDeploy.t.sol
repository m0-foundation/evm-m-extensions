// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { UnsafeUpgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { DeployUSDZBase } from "../../script/deploy/vendor/braid/DeployUSDZBase.sol";

import { MExtensionUpgrade } from "../utils/Mocks.sol";

contract USDZDeployTests is DeployUSDZBase, Test {
    uint256 public mainnetFork;
    uint256 public arbitrumFork;

    address public constant DEPLOYER = 0xF2f1ACbe0BA726fEE8d75f3E32900526874740BB; // M0 deployer address

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"), 23535885); // Block before USDZ deployment
        arbitrumFork = vm.createFork(vm.envString("ARBITRUM_RPC_URL"), 387502795); // Block before USDZ deployment
    }

    /* ============ Deploy ============ */

    function testFork_deployEthereumMainnet() external {
        vm.selectFork(mainnetFork);

        vm.deal(DEPLOYER, 100 ether);

        vm.startPrank(DEPLOYER);

        (, address proxy, ) = _deployUSDZ(
            DEPLOYER,
            M_TOKEN,
            SWAP_FACILITY,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            pauser,
            forcedTransferManager
        );

        vm.stopPrank();

        assertEq(proxy, _getCreate3Address(DEPLOYER, _computeSalt(DEPLOYER, "EarnerDelta")));
    }

    function testFork_deployArbitrumMainnet() external {
        vm.selectFork(arbitrumFork);

        vm.deal(DEPLOYER, 100 ether);

        vm.startPrank(DEPLOYER);

        (, address proxy, ) = _deployUSDZ(
            DEPLOYER,
            M_TOKEN,
            SWAP_FACILITY,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            pauser,
            forcedTransferManager
        );

        vm.stopPrank();

        assertEq(proxy, _getCreate3Address(DEPLOYER, _computeSalt(DEPLOYER, "EarnerDelta")));
    }

    /* ============ Upgrade ============ */

    function testFork_upgradeEthereumMainnet() external {
        vm.selectFork(mainnetFork);

        vm.deal(DEPLOYER, 100 ether);

        (, address proxy, ) = _deployUSDZ(
            DEPLOYER,
            M_TOKEN,
            SWAP_FACILITY,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            pauser,
            forcedTransferManager
        );

        UnsafeUpgrades.upgradeProxy(proxy, address(new MExtensionUpgrade()), "", admin);

        assertEq(MExtensionUpgrade(proxy).bar(), 1);
    }

    function testFork_upgradeArbitrumMainnet() external {
        vm.selectFork(arbitrumFork);

        vm.deal(DEPLOYER, 100 ether);

        (, address proxy, ) = _deployUSDZ(
            DEPLOYER,
            M_TOKEN,
            SWAP_FACILITY,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            pauser,
            forcedTransferManager
        );

        UnsafeUpgrades.upgradeProxy(proxy, address(new MExtensionUpgrade()), "", admin);

        assertEq(MExtensionUpgrade(proxy).bar(), 1);
    }
}
