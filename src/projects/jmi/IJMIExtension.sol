// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IMYieldToOne } from "../yieldToOne/interfaces/IMYieldToOne.sol";

interface IJMIExtension is IMYieldToOne {
    /* ============ Events ============ */

    /**
     * @notice Emitted when asset cap is set.
     * @param  asset Address of the asset.
     * @param  cap   Maximum allowed amount of `asset` that can back the extension.
     */
    event AssetCapSet(address indexed asset, uint256 cap);

    /**
     * @notice Emitted when an asset is replaced with M.
     * @param  asset       Address of the asset.
     * @param  assetAmount Amount of asset replaced with M.
     * @param  recipient   Address that received the M.
     * @param  mAmount     Amount of M sent to the recipient.
     */
    event AssetReplacedWithM(address indexed asset, uint256 assetAmount, address indexed recipient, uint256 mAmount);

    /* ============ Custom Errors ============ */

    /**
     * @notice Emitted if the asset cap is reached.
     * @param  asset Address of the asset.
     */
    error AssetCapReached(address asset);

    /**
     * @notice Emitted if `replaceAssetWithM` is called but there is not enough asset to replace M with.
     * @param  asset          Address of the asset.
     * @param  amount         Amount of M to unwrap requested.
     * @param  assetAvailable Amount of M available.
     */
    error InsufficientAssetBacking(address asset, uint256 amount, uint256 assetAvailable);

    /**
     * @notice Emitted when wrapping `asset` for extension token and receiving less than expected.
     * @param  asset          Address of the asset.
     * @param  amountExpected Amount of `asset` expected.
     * @param  amountReceived Amount of `asset` received.
     */
    error InsufficientAssetReceived(address asset, uint256 amountExpected, uint256 amountReceived);

    /**
     * @notice Emitted if `unwrap()` is called but there is not enough M to unwrap with.
     * @param  amount     Amount of M to unwrap requested.
     * @param  mAvailable Amount of M available.
     */
    error InsufficientMBacking(uint256 amount, uint256 mAvailable);

    /**
     * @notice Emitted if an invalid asset is used.
     * @param  asset Address of the invalid asset.
     */
    error InvalidAsset(address asset);

    /// @notice Emitted in initializer if Asset Cap Manager is 0x0.
    error ZeroAssetCapManager();

    /* ============ Interactive Functions ============ */

    /*
     * @notice Mint extension tokens by depositing `asset` tokens.
     * @dev    MUST only be callable by the SwapFacility.
     * @dev    `amount` must be formatted in the `asset` token's decimals.
     * @param  asset     Address of the asset to deposit.
     * @param  recipient Address that will receive the extension tokens.
     * @param  amount    Amount of extension tokens to mint.
     */
    function wrap(address asset, address recipient, uint256 amount) external;

    /*
     * @notice Allows a M holder to swap M for the `asset` token.
     * @dev    MUST only be callable by the SwapFacility.
     * @dev    `amount` MUST be formatted in the M token's decimals.
     * @param  asset     Address of the asset to receive.
     * @param  recipient Address that will receive the `asset` token.
     * @param  amount    Amount of M to swap for `asset` token, formatted in M decimals.
     */
    function replaceAssetWithM(address asset, address recipient, uint256 amount) external;

    /*
     * @notice Sets the asset cap for a given `asset`.
     * @dev    MUST only be callable by an account with the ASSET_CAP_MANAGER_ROLE.
     * @param  asset Address of the asset.
     * @param  cap   Maximum allowed amount of `asset` that can back the extension.
     */
    function setAssetCap(address asset, uint256 cap) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The role that can set the assets cap.
    function ASSET_CAP_MANAGER_ROLE() external view returns (bytes32);

    /// @notice Number of decimals used by the M token.
    function M_DECIMALS() external view returns (uint8);

    /// @notice Gets the cached balance of a given asset held by the extension.
    function assetBalanceOf(address asset) external view returns (uint256);

    /// @notice Gets the asset cap for a given asset.
    function assetCap(address asset) external view returns (uint256);

    /// @notice Gets the cached decimals of a given asset.
    function assetDecimals(address asset) external view returns (uint8);

    /// @notice Gets the total non-M assets held by the extension.
    function totalAssets() external view returns (uint256);

    /// @notice Checks if an asset is allowed as backing.
    function isAllowedAsset(address asset) external view returns (bool);

    /**
     * @notice Checks if wrapping a `amount` of `asset` is allowed.
     * @dev    `amount` MUST be formatted in `asset`'s decimals.
     * @param  asset  Address of the asset.
     * @param  amount Amount of `asset` to wrap.
     * @return True if allowed, false otherwise.
     */
    function isAllowedToWrap(address asset, uint256 amount) external view returns (bool);

    /*
     * @notice Checks if unwrapping `amount` of extension tokens is allowed.
     * @dev    `amount` MUST be formatted in extension's decimals (i.e. 6).
     * @param  amount Amount of extension tokens to unwrap, formatted in extension's decimals.
     * @return True if allowed, false otherwise.
     */
    function isAllowedToUnwrap(uint256 amount) external view returns (bool);

    /**
     * @notice Checks if replacing `asset` with M is allowed.
     * @dev    `amount` MUST be formatted in `asset`'s decimals.
     * @param  asset  Address of the asset.
     * @param  amount Amount of `asset` to replace, formatted in `asset`'s decimals.
     * @return True if allowed, false otherwise.
     */
    function isAllowedToReplaceAssetWithM(address asset, uint256 amount) external view returns (bool);
}
