// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { MYieldToOneVaultWithFee, IAsset } from "../../src/vaults/MYieldToOneVaultWithFee.sol";
import { BaseUnitTest } from "../utils/BaseUnitTest.sol";
import { MYieldToOneHarness } from "../harness/MYieldToOneHarness.sol";
import { MYieldToOne } from "../../src/projects/yieldToOne/MYieldToOne.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract MYieldToOneVaultWithFeeTest is BaseUnitTest {
    MYieldToOneVaultWithFee public vault;
    MYieldToOneHarness public mYieldToOne;

    string public constant ASSET_NAME = "VAULT USD";
    string public constant ASSET_SYMBOL = "VAULT USD";

    string public constant VAULT_NAME = "VAULTED USD";
    string public constant VAULT_SYMBOL = "VAULTED USD";

    function setUp() public override {
        super.setUp();

        mYieldToOne = MYieldToOneHarness(
            Upgrades.deployTransparentProxy(
                "MYieldToOneHarness.sol:MYieldToOneHarness",
                admin,
                abi.encodeWithSelector(
                    MYieldToOne.initialize.selector,
                    ASSET_NAME,
                    ASSET_SYMBOL,
                    yieldRecipient,
                    admin,
                    freezeManager,
                    yieldRecipientManager
                ),
                mExtensionDeployOptions
            )
        );

        vault = new MYieldToOneVaultWithFee(
            VAULT_NAME,
            VAULT_SYMBOL,
            IAsset(address(mYieldToOne)),
            admin,
            1_000 // 10%
        );

        vm.prank(yieldRecipientManager);
        mYieldToOne.setYieldRecipient(address(vault));
    }

    function test_claimYieldMintsCorrectShares() public {
        mToken.setBalanceOf(address(mYieldToOne), 20e6);

        mYieldToOne.setBalanceOf(alice, 20e6);
        mYieldToOne.setTotalSupply(20e6);

        vm.prank(alice);
        mYieldToOne.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.deposit(10e6, alice);

        mToken.setBalanceOf(address(mYieldToOne), 30e6);

        vault.claimYield();

        uint256 adminVaultShares = vault.balanceOf(admin);
        uint256 adminVaultAssets = vault.previewRedeem(adminVaultShares);

        uint256 aliceVaultShares = vault.balanceOf(alice);
        uint256 aliceVaultAssets = vault.previewRedeem(aliceVaultShares);

        uint256 vaultTotalSupply = vault.totalSupply();

        assertEq(adminVaultShares, 526315, "admin vault shares should be 526315");
        assertApproxEqAbs(adminVaultAssets, 1e6, 2, "admin shares be worth 1 token, 10% of 10 token yield");

        assertEq(aliceVaultShares, 10e6, "alice's shares should still be 10");
        assertApproxEqAbs(aliceVaultAssets, 19e6, 2, "alice's shares should be worth 19 tokens");

        assertEq(vaultTotalSupply, 10e6 + 526315, "vault total supply should reflect admin shares");
    }

    function test_depositTriggersYieldClaim() public {
        address bob = makeAddr("bob");

        mYieldToOne.setBalanceOf(alice, 10e6);
        mYieldToOne.setBalanceOf(bob, 10e6);

        mYieldToOne.setTotalSupply(20e6);

        mToken.setBalanceOf(address(mYieldToOne), 20e6);

        vm.prank(alice);
        mYieldToOne.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.deposit(10e6, alice);

        mToken.setBalanceOf(address(mYieldToOne), 30e6);

        vm.prank(bob);
        mYieldToOne.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        vault.deposit(10e6, bob);

        uint256 aliceShares = vault.balanceOf(alice);
        uint256 aliceAssets = vault.previewRedeem(aliceShares);

        uint256 bobShares = vault.balanceOf(bob);
        uint256 bobAssets = vault.previewRedeem(bobShares);

        uint256 adminShares = vault.balanceOf(admin);
        uint256 adminAssets = vault.previewRedeem(adminShares);

        uint256 vaultTotalSupply = vault.totalSupply();

        assertEq(aliceShares, 10e6, "alice's shares should still be 10");
        assertApproxEqAbs(aliceAssets, 19e6, 2, "alice's shares should be worth 19 tokens");

        assertEq(bobShares, 5263157, "bob's shares should be 5263157");
        assertApproxEqAbs(bobAssets, 10e6, 2, "bob's shares should be worth 10 tokens");

        assertEq(adminShares, 526315, "admin vault shares should be 526315");
        assertApproxEqAbs(adminAssets, 1e6, 2, "admin shares be worth 1 token, 10 percent of 10 token yield");

        assertEq(vaultTotalSupply, 10e6 + 5263157 + 526315, "vault total supply should reflect admin shares");
    }

    function test_mintTriggersYieldClaim() public {
        address bob = makeAddr("bob");

        mYieldToOne.setBalanceOf(alice, 10e6);
        mYieldToOne.setBalanceOf(bob, 10e6);

        mYieldToOne.setTotalSupply(20e6);

        mToken.setBalanceOf(address(mYieldToOne), 20e6);

        vm.prank(alice);
        mYieldToOne.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.mint(10e6, alice);

        mToken.setBalanceOf(address(mYieldToOne), 30e6);

        vm.prank(bob);
        mYieldToOne.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        vault.mint(5263157, bob);

        uint256 aliceShares = vault.balanceOf(alice);
        uint256 aliceAssets = vault.previewRedeem(aliceShares);

        uint256 bobShares = vault.balanceOf(bob);
        uint256 bobAssets = vault.previewRedeem(bobShares);

        uint256 adminShares = vault.balanceOf(admin);
        uint256 adminAssets = vault.previewRedeem(adminShares);

        uint256 vaultTotalSupply = vault.totalSupply();

        assertEq(aliceShares, 10e6, "alice's shares should still be 10");
        assertApproxEqAbs(aliceAssets, 19e6, 2, "alice's shares should be worth 19 tokens");

        assertEq(bobShares, 5263157, "bob's shares should be 5263157");
        assertApproxEqAbs(bobAssets, 10e6, 2, "bob's shares should be worth 10 tokens");

        assertEq(adminShares, 526315, "admin vault shares should be 526315");
        assertApproxEqAbs(adminAssets, 1e6, 2, "admin shares be worth 1 token, 10 percent of 10 token yield");

        assertEq(vaultTotalSupply, 10e6 + 5263157 + 526315, "vault total supply should reflect admin shares");
    }

    function test_redeemTriggersYieldClaim() public {
        mYieldToOne.setBalanceOf(alice, 10e6);

        mYieldToOne.setTotalSupply(10e6);

        mToken.setBalanceOf(address(mYieldToOne), 10e6);

        vm.prank(alice);
        mYieldToOne.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.deposit(10e6, alice);

        mToken.setBalanceOf(address(mYieldToOne), 20e6);

        uint256 aliceYieldToOneBlanceBefore = mYieldToOne.balanceOf(alice);

        vm.prank(alice);
        vault.redeem(10e6, alice, alice);

        uint256 vaultTotalSupply = vault.totalSupply();

        uint256 aliceYieldToOneBalanceAfter = mYieldToOne.balanceOf(alice);

        uint256 adminShares = vault.balanceOf(admin);

        uint256 adminAssets = vault.previewRedeem(adminShares);

        assertEq(adminShares, 526315, "admin should have 526315 shares");

        assertApproxEqAbs(adminAssets, 1e6, 1, "admin should have one token underlying their shares");

        assertEq(vaultTotalSupply, adminShares, "admin should own all remaining shares");

        assertApproxEqAbs(
            aliceYieldToOneBalanceAfter - aliceYieldToOneBlanceBefore,
            19e6,
            1,
            "alice should have received 19 tokens on redeem"
        );
    }

    function test_withdrawalTriggersYieldClaim() public {
        mYieldToOne.setBalanceOf(alice, 10e6);

        mYieldToOne.setTotalSupply(10e6);

        mToken.setBalanceOf(address(mYieldToOne), 10e6);

        vm.prank(alice);
        mYieldToOne.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.deposit(10e6, alice);

        mToken.setBalanceOf(address(mYieldToOne), 20e6);

        uint256 aliceAssets = vault.assetsOf(alice);

        uint256 aliceYieldToOneBlanceBefore = mYieldToOne.balanceOf(alice);

        vm.prank(alice);
        vault.withdraw(aliceAssets, alice, alice);

        uint256 aliceYieldToOneBalanceAfter = mYieldToOne.balanceOf(alice);

        uint256 vaultTotalSupply = vault.totalSupply();

        uint256 aliceShares = vault.balanceOf(alice);
        uint256 aliceAssetsAfter = vault.assetsOf(alice);

        uint256 adminShares = vault.balanceOf(admin);
        uint256 adminAssets = vault.assetsOf(admin);

        assertEq(adminShares, 526315, "admin should have 526315 shares");
        assertApproxEqAbs(adminAssets, 1e6, 2, "admin should have one token underlying their shares");

        assertEq(vaultTotalSupply, adminShares, "admin should own all remaining shares");

        assertApproxEqAbs(
            aliceYieldToOneBalanceAfter - aliceYieldToOneBlanceBefore,
            19e6,
            1,
            "alice should have received 19 tokens on redeem"
        );
    }
}
