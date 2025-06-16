// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";
import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { Lock } from "../lib/universal-router/contracts/base/Lock.sol";

import { ISwapFacility } from "./interfaces/ISwapFacility.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";
import { IMExtension } from "./interfaces/IMExtension.sol";

contract SwapFacility is Ownable, Lock, ISwapFacility {
    bytes32 public constant EARNERS_LIST_IGNORED_KEY = "earners_list_ignored";
    bytes32 public constant EARNERS_LIST_NAME = "earners";

    /// @inheritdoc ISwapFacility
    address public immutable mToken;

    /// @inheritdoc ISwapFacility
    address public immutable registrar;

    constructor(address mToken_, address registrar_, address owner_) Ownable(owner_) {
        if ((mToken = mToken_) == address(0)) revert ZeroMToken();
        if ((registrar = registrar_) == address(0)) revert ZeroRegistrar();
    }

    /* ============ Interactive Functions ============ */

    function swap(address extensionIn, address extensionOut, uint256 amount, address recipient) external isNotLocked {
        _revertIfNotApprovedExtension(extensionIn);
        _revertIfNotApprovedExtension(extensionOut);
        _revertIfZeroAmount(amount);
        _revertIfZeroRecipient(recipient);

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amount);

        address mToken_ = mToken;
        uint256 balanceBefore = IERC20(mToken_).balanceOf(address(this));

        IMExtension(extensionIn).unwrap(address(this), amount);

        amount = IERC20(mToken_).balanceOf(address(this)) - balanceBefore;

        IMExtension(extensionOut).wrap(recipient, amount);

        emit Swapped(extensionIn, extensionOut, amount, recipient);
    }

    function swapM(address extensionOut, uint256 amount, address recipient) external isNotLocked {
        _revertIfNotApprovedExtension(extensionOut);
        _revertIfZeroAmount(amount);
        _revertIfZeroRecipient(recipient);

        IERC20(mToken).transferFrom(msg.sender, address(this), amount);
        IMExtension(extensionOut).wrap(recipient, amount);

        emit SwappedM(extensionOut, amount, recipient);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc ISwapFacility
    function msgSender() public view returns (address) {
        return _getLocker();
    }

    /* ============ Private View/Pure Functions ============ */

    function _revertIfZeroAmount(uint256 amount) private pure {
        if (amount == 0) revert ZeroAmount();
    }

    function _revertIfZeroRecipient(address recipient) private pure {
        if (recipient == address(0)) revert ZeroRecipient();
    }

    /**
     * @dev   Reverts if `extension` is not an approved earner.
     * @param extension Address of an extension.
     */
    function _revertIfNotApprovedExtension(address extension) private view {
        if (!_isApprovedEarner(extension)) revert NotApprovedExtension(extension);
    }

    /// @dev Returns whether this contract is a Registrar-approved earner.
    function _isApprovedEarner(address extension) private view returns (bool) {
        return
            IRegistrarLike(registrar).get(EARNERS_LIST_IGNORED_KEY) != bytes32(0) ||
            IRegistrarLike(registrar).listContains(EARNERS_LIST_NAME, extension);
    }
}
