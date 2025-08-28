// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IMYieldToOne } from "../projects/yieldToOne/IMYieldToOne.sol";
import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";

interface IAsset is IMYieldToOne, IERC20 {
    function decimals() external view returns (uint8);
}

contract MYieldToOneVaultWithFeeBase {
    using FixedPointMathLib for uint256;

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

    constructor(IAsset _asset, address _admin, uint256 _fee) {
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

        _issue(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        _claimYield();

        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        ASSET.transferFrom(msg.sender, address(this), assets);

        _issue(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256 shares) {
        _claimYield();

        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        _claim(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        ASSET.transfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        _claimYield();

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _claim(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        ASSET.transfer(receiver, assets);
    }

    function claimYield() public {
        _claimYield();
    }

    function _claimYield() internal virtual {
        uint256 yield = ASSET.claimYield();
        uint256 totalAssets = totalAssets();
        if (yield == 0 || totalAssets == 0) return;
        uint256 adminShares = _adminYieldShares(yield, totalAssets);
        if (adminShares != 0) _issue(admin, adminShares);
    }

    function _adminYieldShares(uint256 yield, uint256 totalAssets) internal view returns (uint256) {
        uint256 yieldToAdmin = (yield * fee) / MAX_FEE;

        return yieldToAdmin.mulDivDown(_totalIssued(), totalAssets - yieldToAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function assetsOf(address account) public view returns (uint256) {
        uint256 yield = ASSET.yield();
        uint256 totalAssetsPlusYield = totalAssets() + yield;

        uint256 adminYieldShares = _adminYieldShares(yield, totalAssetsPlusYield);

        uint256 shares = _balanceOf(account);

        uint256 supply = _totalIssued();

        return supply == 0 ? shares : shares.mulDivDown(totalAssetsPlusYield, supply + adminYieldShares);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256) {
        return ASSET.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = _totalIssued(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = _totalIssued(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = _totalIssued(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = _totalIssued(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
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
        return convertToAssets(_balanceOf(owner));
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return _balanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _totalIssued() internal view virtual returns (uint256) {}
    function _balanceOf(address owner) internal view virtual returns (uint256) {}
    function _issue(address to, uint256 amount) internal virtual {}
    function _claim(address from, uint256 amount) internal virtual {}
}
