// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";

import { TransferHelper } from "../../../lib/common/src/libs/TransferHelper.sol";

import { Pausable } from "../../components/pausable/Pausable.sol";

import { IMTokenLike } from "../../interfaces/IMTokenLike.sol";
import { ISwapFacility } from "../../swap/interfaces/ISwapFacility.sol";

import { IMYieldToOne } from "../yieldToOne/IMYieldToOne.sol";
import { MYieldToOne } from "../yieldToOne/MYieldToOne.sol";

import { IJMIExtension } from "./IJMIExtension.sol";

abstract contract JMIExtensionLayout {
    struct JMIExtensionStorageStruct {
        // All supported collateral assets and their caps.
        // If an asset is not present in the mapping or has a cap of 0, it is not allowed.
        // Cap amount MUST be formatted in the asset's decimals (i.e. 18 decimals for DAI).
        // Primary asset (M) is implicit and has no cap.
        mapping(address asset => uint256 capAmount) assetCap;
        // Total amount of non M assets backing the extension token, formatted in extension decimals (i.e. 6 decimals).
        uint256 totalAssets;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.JMIExtension")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _JMI_EXTENSION_STORAGE_LOCATION =
        0x4717d46f2e033163981fa31651301a35281b6b08316965d315fd1577bad94b00;

    function _getJMIExtensionStorageLocation() internal pure returns (JMIExtensionStorageStruct storage $) {
        assembly {
            $.slot := _JMI_EXTENSION_STORAGE_LOCATION
        }
    }
}

/**
 * @title  JMIExtension
 * @notice Upgradeable ERC20 Token contract for wrapping M into a non-rebasing token
 *         with yield claimable by a single recipient and JMI (Just Mint It) backing model.
 *         The JMI backing model allows users to mint the extension token
 *         by depositing either M or an allowed asset token.
 *         It assumes that both tokens are pegged 1:1.
 * @author M0 Labs
 */
contract JMIExtension is IJMIExtension, JMIExtensionLayout, MYieldToOne, Pausable {
    using TransferHelper for IERC20;

    /* ============ Variables ============ */

    /// @inheritdoc IJMIExtension
    bytes32 public constant ASSET_CAP_MANAGER_ROLE = keccak256("ASSET_CAP_MANAGER_ROLE");

    /// @inheritdoc IJMIExtension
    uint8 public constant M_DECIMALS = 6;

    /* ============ Constructor ============ */

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs JMIExtension Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken       The address of $M token.
     * @param  swapFacility The address of Swap Facility.
     */
    constructor(address mToken, address swapFacility) MYieldToOne(mToken, swapFacility) {}

    /* ============ Initializer ============ */

    /**
     * @dev   Initializes the M extension token with JMI backing model and yield claimable by a single recipient.
     * @param name                  The name of the token (e.g. "Just Mint It").
     * @param symbol                The symbol of the token (e.g. "JMI").
     * @param yieldRecipient        The address of a yield recipient.
     * @param admin                 The address of an admin.
     * @param assetCapManager       The address of an asset cap manager.
     * @param freezeManager         The address of a freeze manager.
     * @param pauser                The address of a pauser.
     * @param yieldRecipientManager The address of a yield recipient manager.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address assetCapManager,
        address freezeManager,
        address pauser,
        address yieldRecipientManager
    ) public virtual initializer {
        __JMIExtension_init(
            name,
            symbol,
            yieldRecipient,
            admin,
            assetCapManager,
            freezeManager,
            pauser,
            yieldRecipientManager
        );
    }

    /**
     * @dev   Initializes the JMIExtension token.
     * @param name                  The name of the token (e.g. "Just Mint It").
     * @param symbol                The symbol of the token (e.g. "JMI").
     * @param yieldRecipient        The address of a yield destination.
     * @param admin                 The address of an admin.
     * @param assetCapManager       The address of an asset cap manager.
     * @param freezeManager         The address of a freeze manager.
     * @param pauser                The address of a pauser.
     * @param yieldRecipientManager The address of a yield recipient setter.
     */
    function __JMIExtension_init(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address assetCapManager,
        address freezeManager,
        address pauser,
        address yieldRecipientManager
    ) internal onlyInitializing {
        __MYieldToOne_init(name, symbol, yieldRecipient, admin, freezeManager, yieldRecipientManager);
        __Pausable_init(pauser);

        _grantRole(ASSET_CAP_MANAGER_ROLE, assetCapManager);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IJMIExtension
    function wrap(address asset, address recipient, uint256 amount) external onlySwapFacility {
        // NOTE: `msg.sender` is always SwapFacility contract.
        //       `ISwapFacility.msgSender()` is used to ensure that the original caller is passed to `_beforeWrap`.
        _wrap(asset, ISwapFacility(msg.sender).msgSender(), recipient, amount);
    }

    /// @inheritdoc IJMIExtension
    function replaceAssetWithM(address asset, address recipient, uint256 amount) external onlySwapFacility {
        _replaceAssetWithM(asset, recipient, amount);
    }

    /* ============ Admin Controlled Interactive Functions ============ */

    /// @inheritdoc IJMIExtension
    function setAssetCap(address asset, uint256 cap) external onlyRole(ASSET_CAP_MANAGER_ROLE) {
        _revertIfInvalidAsset(asset);

        if (assetCap(asset) == cap) return;

        _getJMIExtensionStorageLocation().assetCap[asset] = cap;

        emit AssetCapSet(asset, cap);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IJMIExtension
    function assetCap(address asset) public view returns (uint256) {
        return _getJMIExtensionStorageLocation().assetCap[asset];
    }

    /// @inheritdoc IJMIExtension
    function totalAssets() public view returns (uint256) {
        return _getJMIExtensionStorageLocation().totalAssets;
    }

    /// @inheritdoc IJMIExtension
    function isAllowedAsset(address asset) public view returns (bool) {
        return (asset == mToken) || (_getJMIExtensionStorageLocation().assetCap[asset] != 0);
    }

    /// @inheritdoc IJMIExtension
    function isAllowedToWrap(address asset, uint256 amount) public view returns (bool) {
        if (amount == 0) return false;

        // NOTE: Allow any amount of M (primary asset) to be wrapped into JMI extension token.
        if (asset == mToken) return true;

        unchecked {
            // NOTE: Check cap for other assets.
            return assetCap(asset) >= (IERC20(asset).balanceOf(address(this)) + amount);
        }
    }

    /// @inheritdoc IJMIExtension
    function isAllowedToUnwrap(uint256 amount) external view returns (bool) {
        return amount != 0 && _mBacking() >= amount;
    }

    /// @inheritdoc IJMIExtension
    function isAllowedToReplaceAssetWithM(address asset, uint256 amount) external view returns (bool) {
        return amount != 0 && IERC20(asset).balanceOf(address(this)) >= amount;
    }

    /// @inheritdoc IMYieldToOne
    function yield() public view override(IMYieldToOne, MYieldToOne) returns (uint256) {
        uint256 mBalance_ = _mBalanceOf(address(this));
        uint256 mBacking_ = _mBacking();

        unchecked {
            return mBalance_ > mBacking_ ? mBalance_ - mBacking_ : 0;
        }
    }

    /* ============ Hooks For Internal Interactive Functions ============ */

    /**
     * @dev   Hook called before wrapping `asset` into extension's tokens.
     * @param asset     Address of the asset being deposited.
     * @param account   The account initiating the wrap.
     * @param recipient The address that will receive `amount` of extension tokens.
     * @param amount    The amount of extension tokens to mint.
     */
    function _beforeWrap(address asset, address account, address recipient, uint256 amount) internal view virtual {
        _requireNotPaused();

        if (!isAllowedAsset(asset)) revert AssetNotAllowed(asset);
        if (!isAllowedToWrap(asset, amount)) revert AssetCapReached(asset);

        super._beforeWrap(account, recipient, amount);
    }

    /**
     * @dev   Hook called before unwrapping `amount` of extension tokens for M.
     * @param account The account from which `amount` of tokens is burned.
     * @param amount  The amount of tokens to burn.
     */
    function _beforeUnwrap(address account, uint256 amount) internal view virtual override {
        _requireNotPaused();
        _revertIfInsufficientMBacking(amount);

        super._beforeUnwrap(account, amount);
    }

    /**
     * @dev   Hook called before transferring extension tokens.
     * @param sender    The address from which the tokens are being transferred.
     * @param recipient The address to which the tokens are being transferred.
     * @param amount    The amount of tokens to transfer.
     */
    function _beforeTransfer(address sender, address recipient, uint256 amount) internal view override {
        _requireNotPaused();

        super._beforeTransfer(sender, recipient, amount);
    }

    /* ============ Internal Interactive Functions ============ */

    function _wrap(address asset, address account, address recipient, uint256 amount) internal virtual {
        _revertIfInvalidAsset(asset);
        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        // NOTE: MYieldToOne's `_beforeWrap` checks that `account` and `recipient` are not frozen.
        _beforeWrap(asset, account, recipient, amount);

        // NOTE: Transfers asset from SwapFacility to this contract (amount is in asset decimals).
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        uint256 jmiAmount_ = _fromAssetToExtensionAmount(asset, amount);

        if (asset != mToken) {
            unchecked {
                // Update total non-M asset amount backing JMI extension token.
                _getJMIExtensionStorageLocation().totalAssets += jmiAmount_;
            }
        }

        _mint(recipient, jmiAmount_);
    }

    /*
     * @notice Allows a M holder to swap M for the `asset` token.
     * @dev    `amount` MUST be formatted in the M token's decimals.
     * @param  asset     Address of the asset being replaced.
     * @param  recipient Address that will receive the `asset` token.
     * @param  amount    Amount of M to swap for `asset` token, formatted in M decimals.
     */
    function _replaceAssetWithM(address asset, address recipient, uint256 amount) internal virtual {
        _requireNotPaused();

        if (asset == address(0) || asset == address(mToken)) revert InvalidAsset(asset);

        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        uint256 assetAmount = _fromExtensionToAssetAmount(asset, amount);

        _revertIfInsufficientAssetBacking(asset, assetAmount);

        // NOTE: Update total non-M asset amount backing JMI extension token.
        _getJMIExtensionStorageLocation().totalAssets -= amount;

        // NOTE: `msg.sender` is always SwapFacility contract.
        // NOTE: The behavior of `IMTokenLike.transferFrom` is known, so its return can be ignored.
        IMTokenLike(mToken).transferFrom(msg.sender, address(this), amount);

        IERC20(asset).safeTransfer(recipient, assetAmount);

        emit AssetReplacedWithM(asset, assetAmount, recipient, amount);
    }

    /* ============ Internal View Functions ============ */

    /// @dev Returns the current supply of M backing the extension token.
    function _mBacking() internal view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 totalAssets_ = totalAssets();

        unchecked {
            return totalSupply_ > totalAssets_ ? totalSupply_ - totalAssets_ : 0;
        }
    }

    /**
     * @dev   Reverts if `asset` is address(0).
     * @param asset Address of an asset.
     */
    function _revertIfInvalidAsset(address asset) internal pure {
        if (asset == address(0)) revert InvalidAsset(asset);
    }

    /**
     * @dev   Reverts if there is not enough M backing to unwrap the requested amount.
     * @param amount Amount of M to unwrap.
     */
    function _revertIfInsufficientMBacking(uint256 amount) internal view {
        uint256 mBacking_ = _mBacking();
        if (amount > mBacking_) revert InsufficientMBacking(amount, mBacking_);
    }

    /**
     * @dev   Reverts if `amount` of `asset` is greater than the available balance held by the extension.
     * @param asset  Address of an asset.
     * @param amount Amount of `asset` to check.
     */
    function _revertIfInsufficientAssetBacking(address asset, uint256 amount) internal view {
        uint256 assetBacking_ = IERC20(asset).balanceOf(address(this));
        if (amount > assetBacking_) revert InsufficientAssetBacking(asset, amount, assetBacking_);
    }

    /**
     * @dev    Converts `amount` from asset decimals to extension decimals.
     * @param  asset  Address of an asset.
     * @param  amount Amount in `asset` decimals.
     * @return Amount in extension decimals.
     */
    function _fromAssetToExtensionAmount(address asset, uint256 amount) internal view returns (uint256) {
        return _convertAmounts(IERC20(asset).decimals(), M_DECIMALS, amount);
    }

    /**
     * @dev    Converts `amount` from extension decimals to asset decimals.
     * @param  asset  Address of an asset.
     * @param  amount Amount in extension decimals.
     * @return Amount in `asset` decimals.
     */
    function _fromExtensionToAssetAmount(address asset, uint256 amount) internal view returns (uint256) {
        return _convertAmounts(M_DECIMALS, IERC20(asset).decimals(), amount);
    }

    /* ============ Internal Pure Functions ============ */

    /**
     * @dev    Converts `amount` from `fromDecimals` to `toDecimals`.
     * @param  fromDecimals The decimals of the input amount.
     * @param  toDecimals   The decimals of the output amount.
     * @param  amount       The amount to convert.
     * @return The converted amount.
     */
    function _convertAmounts(uint8 fromDecimals, uint8 toDecimals, uint256 amount) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) return amount;

        return
            fromDecimals > toDecimals
                ? amount / (10 ** (fromDecimals - toDecimals))
                : amount * (10 ** (toDecimals - fromDecimals));
    }
}
