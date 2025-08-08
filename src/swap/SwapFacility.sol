// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

import { IMTokenLike } from "../interfaces/IMTokenLike.sol";
import { IMExtension } from "../interfaces/IMExtension.sol";

import { ISwapFacility } from "./interfaces/ISwapFacility.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";

import { ReentrancyLock } from "./ReentrancyLock.sol";

abstract contract SwapFacilityUpgradeableStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.SwapFacility
    struct SwapFacilityStorageStruct {
        mapping(address extension => bool permissioned) permissionedExtensions;
        mapping(address extension => mapping(address mSwapper => bool allowed)) permissionedMSwappers;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.SwapFacility")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _SWAP_FACILITY_EXTENDED_STORAGE_LOCATION =
        0x2f6671d90ec6fb8a38d5fa4043e503b2789e716b6e5219d1b20da9c6434dde00;

    function _getSwapFacilityStorageLocation() internal pure returns (SwapFacilityStorageStruct storage $) {
        assembly {
            $.slot := _SWAP_FACILITY_EXTENDED_STORAGE_LOCATION
        }
    }
}

/**
 * @title  Swap Facility
 * @notice A contract responsible for swapping between $M Extensions.
 * @author M0 Labs
 */
contract SwapFacility is ISwapFacility, ReentrancyLock, SwapFacilityUpgradeableStorageLayout {
    /// @inheritdoc ISwapFacility
    bytes32 public constant EARNERS_LIST_NAME = "earners";

    /// @inheritdoc ISwapFacility
    bytes32 public constant EARNERS_LIST_IGNORED_KEY = "earners_list_ignored";

    /// @inheritdoc ISwapFacility
    bytes32 public constant M_SWAPPER_ROLE = keccak256("M_SWAPPER_ROLE");

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable mToken;

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable registrar;

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs SwapFacility Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken_      The address of $M token.
     * @param  registrar_   The address of Registrar.
     */
    constructor(address mToken_, address registrar_) {
        _disableInitializers();

        if ((mToken = mToken_) == address(0)) revert ZeroMToken();
        if ((registrar = registrar_) == address(0)) revert ZeroRegistrar();
    }

    /* ============ Initializer ============ */

    /**
     * @notice Initializes SwapFacility Proxy.
     * @param  admin Address of the SwapFacility admin.
     */
    function initialize(address admin) external initializer {
        __ReentrancyLock_init(admin);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc ISwapFacility
    function swap(address extensionIn, address extensionOut, uint256 amount, address recipient) external isNotLocked {
        _swap(extensionIn, extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapWithPermit(
        address extensionIn,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isNotLocked {
        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, v, r, s) {} catch {}

        _swap(extensionIn, extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapWithPermit(
        address extensionIn,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external isNotLocked {
        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        _swap(extensionIn, extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInM(address extensionOut, uint256 amount, address recipient) external isNotLocked {
        _swapInM(extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInMWithPermit(
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isNotLocked {
        try IMTokenLike(mToken).permit(msg.sender, address(this), amount, deadline, v, r, s) {} catch {}

        _swapInM(extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInMWithPermit(
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external isNotLocked {
        try IMTokenLike(mToken).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        _swapInM(extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutM(address extensionIn, uint256 amount, address recipient) external isNotLocked {
        _swapOutM(extensionIn, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutMWithPermit(
        address extensionIn,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isNotLocked {
        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, v, r, s) {} catch {}

        _swapOutM(extensionIn, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutMWithPermit(
        address extensionIn,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external isNotLocked {
        try IMExtension(extensionIn).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        _swapOutM(extensionIn, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function setPermissionedExtension(address extension, bool permissioned) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (extension == address(0)) revert ZeroExtension();

        if (isPermissionedExtension(extension) == permissioned) return;

        _getSwapFacilityStorageLocation().permissionedExtensions[extension] = permissioned;

        emit PermissionedExtensionSet(extension, permissioned);
    }

    /// @inheritdoc ISwapFacility
    function setPermissionedMSwapper(
        address extension,
        address swapper,
        bool allowed
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (extension == address(0)) revert ZeroExtension();
        if (swapper == address(0)) revert ZeroSwapper();

        if (isPermissionedMSwapper(extension, swapper) == allowed) return;

        _getSwapFacilityStorageLocation().permissionedMSwappers[extension][swapper] = allowed;

        emit PermissionedMSwapperSet(extension, swapper, allowed);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc ISwapFacility
    function isPermissionedExtension(address extension) public view returns (bool) {
        return _getSwapFacilityStorageLocation().permissionedExtensions[extension];
    }

    /// @inheritdoc ISwapFacility
    function isPermissionedMSwapper(address extension, address swapper) public view returns (bool) {
        return _getSwapFacilityStorageLocation().permissionedMSwappers[extension][swapper];
    }

    /// @inheritdoc ISwapFacility
    function isMSwapper(address swapper) public view returns (bool) {
        return hasRole(M_SWAPPER_ROLE, swapper);
    }

    /// @inheritdoc ISwapFacility
    function msgSender() public view returns (address) {
        return _getLocker();
    }

    /* ============ Private Interactive Functions ============ */
    /**
     * @notice Swaps one $M Extension to another.
     * @param  extensionIn  The address of the $M Extension to swap from.
     * @param  extensionOut The address of the $M Extension to swap to.
     * @param  amount       The amount to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     */
    function _swap(address extensionIn, address extensionOut, uint256 amount, address recipient) private {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedExtension(extensionOut);

        _revertIfPermissionedExtension(extensionIn);
        _revertIfPermissionedExtension(extensionOut);

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amount);

        // NOTE: Added to support WrappedM V1 extension, should be removed in the future after upgrade to V2.
        uint256 mBalanceBefore = _mBalanceOf(address(this));

        // NOTE: Amount and recipient validation is performed in Extensions.
        // Recipient parameter is ignored in the MExtension, keeping it for backward compatibility.
        IMExtension(extensionIn).unwrap(address(this), amount);

        // NOTE: Calculate amount as $M Token balance difference
        //       to account for WrappedM V1 rounding errors.
        amount = _mBalanceOf(address(this)) - mBalanceBefore;

        IERC20(mToken).approve(extensionOut, amount);
        IMExtension(extensionOut).wrap(recipient, amount);

        emit Swapped(extensionIn, extensionOut, amount, recipient);
    }

    /**
     * @notice Swaps $M token to $M Extension.
     * @param  extensionOut The address of the M Extension to swap to.
     * @param  amount       The amount of $M token to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     */
    function _swapInM(address extensionOut, uint256 amount, address recipient) private {
        _revertIfNotApprovedExtension(extensionOut);
        _revertIfNotApprovedSwapper(extensionOut, msg.sender);

        IERC20(mToken).transferFrom(msg.sender, address(this), amount);
        IERC20(mToken).approve(extensionOut, amount);
        IMExtension(extensionOut).wrap(recipient, amount);

        emit SwappedInM(extensionOut, amount, recipient);
    }

    /**
     * @notice Swaps $M Extension to $M token.
     * @param  extensionIn The address of the $M Extension to swap from.
     * @param  amount      The amount of $M Extension tokens to swap.
     * @param  recipient   The address to receive $M tokens.
     */
    function _swapOutM(address extensionIn, uint256 amount, address recipient) private {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedSwapper(extensionIn, msg.sender);

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amount);

        // NOTE: Added to support WrappedM V1 extension, should be removed in the future after upgrade to V2.
        uint256 mBalanceBefore = _mBalanceOf(address(this));

        // NOTE: Amount and recipient validation is performed in Extensions.
        // Recipient parameter is ignored in the MExtension, keeping it for backward compatibility.
        IMExtension(extensionIn).unwrap(address(this), amount);

        // NOTE: Calculate amount as $M Token balance difference
        //       to account for WrappedM V1 rounding errors.
        amount = _mBalanceOf(address(this)) - mBalanceBefore;

        IERC20(mToken).transfer(recipient, amount);

        emit SwappedOutM(extensionIn, amount, recipient);
    }

    /* ============ Private View/Pure Functions ============ */

    /**
     * @dev    Returns the M Token balance of `account`.
     * @param  account The account being queried.
     * @return balance The M Token balance of the account.
     */
    function _mBalanceOf(address account) internal view returns (uint256) {
        return IMTokenLike(mToken).balanceOf(account);
    }

    /**
     * @dev   Reverts if `extension` is not an approved earner.
     * @param extension Address of an extension.
     */
    function _revertIfNotApprovedExtension(address extension) private view {
        if (!_isApprovedEarner(extension)) revert NotApprovedExtension(extension);
    }

    /**
     * @dev   Reverts if `extension` is a permissioned extension.
     *        A permissioned extension can only be swapped from/to M by an approved swapper.
     * @param extension Address of an extension.
     */
    function _revertIfPermissionedExtension(address extension) private view {
        if (isPermissionedExtension(extension)) revert PermissionedExtension(extension);
    }

    /**
     * @dev   Reverts if `swapper` is not an approved M token swapper.
     * @param swapper Address of the account to check.
     */
    function _revertIfNotApprovedSwapper(address extension, address swapper) private view {
        if (isPermissionedExtension(extension)) {
            if (!isPermissionedMSwapper(extension, swapper)) revert NotApprovedPermissionedSwapper(extension, swapper);
        } else {
            if (!isMSwapper(swapper)) revert NotApprovedSwapper(extension, swapper);
        }
    }

    /**
     * @dev    Checks if the given extension is an approved earner.
     * @param  extension Address of the extension to check.
     * @return True if the extension is an approved earner, false otherwise.
     */
    function _isApprovedEarner(address extension) private view returns (bool) {
        return
            IRegistrarLike(registrar).get(EARNERS_LIST_IGNORED_KEY) != bytes32(0) ||
            IRegistrarLike(registrar).listContains(EARNERS_LIST_NAME, extension);
    }
}
