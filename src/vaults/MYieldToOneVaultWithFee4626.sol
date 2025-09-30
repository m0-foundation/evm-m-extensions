// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IMYieldToOne } from "../projects/yieldToOne/IMYieldToOne.sol";

import {
    ERC20
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {
    IERC20
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {
    Math
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

interface IAsset is IMYieldToOne, IERC20 {
    function decimals() external view returns (uint8);
}

contract MYieldToOneVaultWithFee4626 is ERC20 {
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_FEE = 10000; // 100% in basis points

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    IAsset public immutable ASSET;
    address public admin;
    uint256 public fee;

    constructor(
        string memory _name,
        string memory _symbol,
        IAsset _asset,
        address _admin,
        uint256 _fee
    ) ERC20(_name, _symbol) {
        ASSET = _asset;
        admin = _admin;
        fee = _fee;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
        _claimYield();

        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        ASSET.transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        _claimYield();

        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        ASSET.transferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256 shares) {
        _claimYield();

        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender); // Saves gas for limited approvals.

            if (allowed != type(uint256).max) _approve(owner, msg.sender, allowed - shares);
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        ASSET.transfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        _claimYield();

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender); // Saves gas for limited approvals.

            if (allowed != type(uint256).max) _approve(owner, msg.sender, allowed - shares);
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        ASSET.transfer(receiver, assets);
    }

    function claimYield() public {
        _claimYield();
    }

    function _claimYield() internal {
        uint256 yield = ASSET.claimYield();
        uint256 totalAssets = totalAssets();
        if (yield == 0 || totalAssets == 0) return;
        uint256 adminShares = _adminYieldShares(yield, totalAssets);
        if (adminShares != 0) _mint(admin, adminShares);
    }

    function _adminYieldShares(uint256 yield, uint256 totalAssets) internal view returns (uint256) {
        uint256 yieldToAdmin = (yield * fee) / MAX_FEE;

        return yieldToAdmin.mulDiv(totalSupply(), totalAssets - yieldToAdmin, Math.Rounding.Floor);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function assetsOf(address account) public view returns (uint256) {
        uint256 yield = ASSET.yield();
        uint256 totalAssetsPlusYield = totalAssets() + yield;

        uint256 adminYieldShares = _adminYieldShares(yield, totalAssetsPlusYield);

        uint256 shares = balanceOf(account);

        uint256 supply = totalSupply();

        return
            supply == 0 ? shares : shares.mulDiv(totalAssetsPlusYield, supply + adminYieldShares, Math.Rounding.Floor);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256) {
        return ASSET.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply() is non-zero.

        return supply == 0 ? assets : assets.mulDiv(supply, totalAssets(), Math.Rounding.Floor);
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply() is non-zero.

        return supply == 0 ? shares : shares.mulDiv(totalAssets(), supply, Math.Rounding.Floor);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply() is non-zero.

        return supply == 0 ? shares : shares.mulDiv(totalAssets(), supply, Math.Rounding.Ceil);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply() is non-zero.

        return supply == 0 ? assets : assets.mulDiv(supply, totalAssets(), Math.Rounding.Ceil);
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}
