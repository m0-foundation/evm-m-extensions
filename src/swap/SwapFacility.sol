// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

import { IMTokenLike } from "../interfaces/IMTokenLike.sol";
import { IMExtension } from "../interfaces/IMExtension.sol";

import { ISwapFacility } from "./interfaces/ISwapFacility.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";

import { ReentrancyLock } from "./ReentrancyLock.sol";

/**
 * @title  Swap Facility
 * @notice A contract responsible for swapping between $M Extensions.
 * @author M0 Labs
 */
contract SwapFacility is ISwapFacility, ReentrancyLock {
    bytes32 public constant EARNERS_LIST_IGNORED_KEY = "earners_list_ignored";
    bytes32 public constant EARNERS_LIST_NAME = "earners";

    bytes32 public constant M_SWAPPER_ROLE = keccak256("M_SWAPPER_ROLE");

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable mToken;

    /// @inheritdoc ISwapFacility
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable registrar;

    mapping(address extension => bytes32 swapperRole) public extensionSwapperRole;

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
    function setExtensionSwapperRole(address extension, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (extensionSwapperRole[extension] == role) return;
        extensionSwapperRole[extension] = role;

        emit ExtensionSwapperRoleSet(extension, role);
    }

    /* ============ View/Pure Functions ============ */

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
        _revertIfNotApprovedSwapper(extensionOut, msg.sender, false);

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
        _revertIfNotApprovedSwapper(extensionIn, msg.sender, true);

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
     * @param extension Address of an extension.
     */
    function _revertIfPermissionedExtension(address extension) private view {
        if (extensionSwapperRole[extension] != bytes32(0)) revert PermissionedExtension(extension);
    }

    /**
     * @dev    Reverts if the swapper is not approved for the given extension.
     * @param  extension The address of the $M Extension.
     * @param  swapper   The address of the swapper.
     * @param  swapOut   Indicates swapping direction. True, if swapping the extension out to $M token; otherwise, false.
     */
    function _revertIfNotApprovedSwapper(address extension, address swapper, bool swapOut) private view {
        bytes32 swapperRole = extensionSwapperRole[extension];
        // If the extension is a permissioned extension and
        // has a specific swapper role, check if the swapper has that role.
        if (swapperRole != bytes32(0)) {
            if (!hasRole(swapperRole, swapper)) revert NotApprovedSwapper(extension, swapper);
        }
        // Otherwise, check if the swapper has the default M_SWAPPER_ROLE,
        // but only when trying to swap the extension out to $M token.
        else {
            if (swapOut && !hasRole(M_SWAPPER_ROLE, swapper)) revert NotApprovedSwapper(extension, swapper);
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
