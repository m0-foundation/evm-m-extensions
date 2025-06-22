// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";
import {
    AccessControlUpgradeable
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import { Lock } from "../../lib/universal-router/contracts/base/Lock.sol";

import { IMTokenLike } from "../interfaces/IMTokenLike.sol";
import { IMExtension } from "../interfaces/IMExtension.sol";

import { ISwapFacility } from "./interfaces/ISwapFacility.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";

abstract contract SwapFacilityStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.SwapFacility
    struct SwapFacilityStorageStruct {
        address mToken;
        address registrar;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.SwapFacility")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _SWAP_FACILITY_STORAGE_LOCATION =
        0x2f6671d90ec6fb8a38d5fa4043e503b2789e716b6e5219d1b20da9c6434dde00;

    function _getSwapFacilityStorageLocation() internal pure returns (SwapFacilityStorageStruct storage $) {
        assembly {
            $.slot := _SWAP_FACILITY_STORAGE_LOCATION
        }
    }
}

/**
 * @title  Swap Facility
 * @notice A contract responsible for swapping between $M Extensions.
 * @author M0 Labs
 */
contract SwapFacility is ISwapFacility, AccessControlUpgradeable, Lock {
    bytes32 public constant EARNERS_LIST_IGNORED_KEY = "earners_list_ignored";
    bytes32 public constant EARNERS_LIST_NAME = "earners";
    bytes32 public constant M_SWAPPER_ROLE = keccak256("M_SWAPPER_ROLE");

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable mToken;

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable registrar;

    /**
     * @notice Constructs SwapFacility Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken_    The address of $M token.
     * @param  registrar_ The address of Registrar.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
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
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc ISwapFacility
    function swap(address extensionIn, address extensionOut, uint256 amount, address recipient) external isNotLocked {
        // NOTE: Amount and recipient validation is performed in Extensions.
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedExtension(extensionOut);

        _swap(extensionIn, extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapInM(address extensionOut, uint256 amount, address recipient) external isNotLocked {
        // NOTE: Amount and recipient validation is performed in Extensions.
        _revertIfNotApprovedExtension(extensionOut);

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
        _revertIfNotApprovedExtension(extensionOut);

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
        _revertIfNotApprovedExtension(extensionOut);

        try IMTokenLike(mToken).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        _swapInM(extensionOut, amount, recipient);
    }

    /// @inheritdoc ISwapFacility
    function swapOutM(address extensionIn, uint256 amount, address recipient) external isNotLocked {
        // NOTE: Amount and recipient validation is performed in Extensions.
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedSwapper(msg.sender);

        _swapOutM(extensionIn, amount, recipient);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc ISwapFacility
    function msgSender() external view returns (address) {
        return _getLocker();
    }

    // /// @inheritdoc ISwapFacility
    // function mToken() public view returns (address) {
    //     return _getSwapFacilityStorageLocation().mToken;
    // }

    // /// @inheritdoc ISwapFacility
    // function registrar() public view returns (address) {
    //     return _getSwapFacilityStorageLocation().registrar;
    // }

    /* ============ Private Interactive Functions ============ */

    /**
     * @notice Swaps one $M Extension to another.
     * @param  extensionIn  The address of the $M Extension to swap from.
     * @param  extensionOut The address of the $M Extension to swap to.
     * @param  amount       The amount to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     */
    function _swap(address extensionIn, address extensionOut, uint256 amount, address recipient) private {
        uint256 balanceBefore = _mBalanceOf(address(this));

        IMExtension(extensionIn).unwrap(msg.sender, amount);

        // NOTE: Calculate amount as $M Token balance difference
        //       to account for rounding errors.
        amount = _mBalanceOf(address(this)) - balanceBefore;

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
        uint256 balanceBefore = _mBalanceOf(address(this));
        IMExtension(extensionIn).unwrap(msg.sender, amount);

        // NOTE: Calculate amount as $M Token balance difference
        //       to account for rounding errors.
        amount = _mBalanceOf(address(this)) - balanceBefore;
        IERC20(mToken).transfer(recipient, amount);

        emit SwappedOutM(extensionIn, amount, recipient);
    }

    /**
     * @dev    Returns the M Token balance of `account`.
     * @param  account The account being queried.
     * @return balance The M Token balance of the account.
     */
    function _mBalanceOf(address account) internal view returns (uint256) {
        return IMTokenLike(mToken).balanceOf(account);
    }

    /* ============ Private View/Pure Functions ============ */

    /**
     * @dev   Reverts if `extension` is not an approved earner.
     * @param extension Address of an extension.
     */
    function _revertIfNotApprovedExtension(address extension) private view {
        if (!_isApprovedEarner(extension)) revert NotApprovedExtension(extension);
    }

    /**
     * @dev   Reverts if `account` is not an approved M token swapper.
     * @param account Address of an extension.
     */
    function _revertIfNotApprovedSwapper(address account) private view {
        if (!hasRole(M_SWAPPER_ROLE, account)) revert NotApprovedSwapper(account);
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
