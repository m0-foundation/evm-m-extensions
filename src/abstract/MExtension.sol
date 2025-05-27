// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { ERC20ExtendedUpgradeable } from "../../lib/common/src/ERC20ExtendedUpgradeable.sol";

import { IMTokenLike } from "../interfaces/IMTokenLike.sol";
import { IMExtension } from "../interfaces/IMExtension.sol";

abstract contract MExtensionStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.MExtension
    struct MExtensionStorageStruct {
        address mToken;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.MExtension")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _M_EXTENSION_STORAGE_LOCATION =
        0x4349758e51eb6c8ee9931b1f5b23d0b7b59124948c3d3d99ca2166d742d63d00;

    function _getMExtensionStorageLocation() internal pure returns (MExtensionStorageStruct storage $) {
        assembly {
            $.slot := _M_EXTENSION_STORAGE_LOCATION
        }
    }
}

/**
 * @title MExtension
 * @notice Upgradeable ERC20 Token contract for wrapping M into a non-rebasing token.
 * @author M0 Labs
 */
abstract contract MExtension is IMExtension, MExtensionStorageLayout, ERC20ExtendedUpgradeable {
    /* ============ Initializer ============ */

    /**
     * @notice Initializes the genereic M extension token.
     * @param name    The name of the token (e.g. "HALO USD").
     * @param symbol  The symbol of the token (e.g. "HUSD").
     * @param mToken_ The address of the M Token.
     */
    function __MExtension_init(string memory name, string memory symbol, address mToken_) internal onlyInitializing {
        if ((_getMExtensionStorageLocation().mToken = mToken_) == address(0)) revert ZeroMToken();

        __ERC20ExtendedUpgradeable_init(name, symbol, 6);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMExtension
    function wrap(address recipient, uint256 amount) external {
        _wrap(msg.sender, recipient, amount);
    }

    /// @inheritdoc IMExtension
    function wrapWithPermit(
        address recipient,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        try IMTokenLike(mToken()).permit(msg.sender, address(this), amount, deadline, v, r, s) {} catch {}

        _wrap(msg.sender, recipient, amount);
    }

    /// @inheritdoc IMExtension
    function wrapWithPermit(address recipient, uint256 amount, uint256 deadline, bytes calldata signature) external {
        try IMTokenLike(mToken()).permit(msg.sender, address(this), amount, deadline, signature) {} catch {}

        _wrap(msg.sender, recipient, amount);
    }

    /// @inheritdoc IMExtension
    function unwrap(address recipient, uint256 amount) external {
        _unwrap(msg.sender, recipient, amount);
    }

    /// @inheritdoc IMExtension
    function enableEarning() external virtual {
        if (isEarningEnabled()) revert EarningIsEnabled();

        emit EarningEnabled(_currentMIndex());

        IMTokenLike(mToken()).startEarning();
    }

    /// @inheritdoc IMExtension
    function disableEarning() external virtual {
        if (!isEarningEnabled()) revert EarningIsDisabled();

        IMTokenLike(mToken()).stopEarning(address(this));
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IMExtension
    function isEarningEnabled() public view virtual returns (bool) {
        return IMTokenLike(mToken()).isEarning(address(this));
    }

    /// @inheritdoc IMExtension
    function mToken() public view returns (address) {
        return _getMExtensionStorageLocation().mToken;
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev    Hooks called before wrapping M into M Extension token.
     * @param  account   The account from which M is deposited.
     * @param  recipient The account receiving the minted M Extension token.
     * @param  amount    The amount of M deposited.
     */
    function _beforeWrap(address account, address recipient, uint256 amount) internal virtual {}

    /**
     * @dev    Wraps `amount` M from `account` into M Extension for `recipient`.
     * @param  account   The account from which M is deposited.
     * @param  recipient The account receiving the minted M Extension token.
     * @param  amount    The amount of M deposited.
     */
    function _wrap(address account, address recipient, uint256 amount) internal {
        _beforeWrap(account, recipient, amount);

        // NOTE: The behavior of `IMTokenLike.transferFrom` is known, so its return can be ignored.
        IMTokenLike(mToken()).transferFrom(account, address(this), amount);

        // NOTE: Mints precise amount of $M Extension token to `recipient`.
        //       Option 1: $M transfer from an $M earner to another $M earner ($M Extension in earning state): rounds up → rounds up,
        //                 0, 1, or XX extra wei may be locked in M Extension compared to the minted amount of $M Extension token.
        //       Option 2: $M transfer from an $M non-earner to an $M earner ($M Extension in earning state): precise $M transfer → rounds down,
        //                 0, -1, or -XX wei may be locked in $M Extension compared to the minted amount of $M Extension token.
        _mint(recipient, amount);
    }

    /**
     * @dev   Hook called before unwrapping M Extension token.
     * @param account   The account from which M Extension token is burned.
     * @param recipient The account receiving the withdrawn M.
     * @param amount    The amount of M Extension token burned.
     */
    function _beforeUnwrap(address account, address recipient, uint256 amount) internal virtual {}

    /**
     * @dev    Unwraps `amount` M Extension token from `account_` into M for `recipient`.
     * @param  account   The account from which M Extension token is burned.
     * @param  recipient The account receiving the withdrawn M.
     * @param  amount    The amount of M Extension token burned.
     */
    function _unwrap(address account, address recipient, uint256 amount) internal {
        _beforeUnwrap(account, recipient, amount);

        _burn(account, amount);

        // NOTE: The behavior of `IMTokenLike.transfer` is known, so its return can be ignored.
        // NOTE: Computes the actual decrease in the $M balance of the $M Extension contract.
        //       Option 1: $M transfer from an $M earner ($M Extension in earning state) to another $M earner: round up → rounds up.
        //       Option 2: $M transfer from an $M earner ($M Extension in earning state) to an $M non-earner: round up → precise $M transfer.
        //       In both cases, 0, 1, or XX extra wei may be deducted from the $M Extension contract's $M balance compared to the burned amount of $M Extension token.
        IMTokenLike(mToken()).transfer(recipient, amount);
    }

    /**
     * @dev Mints `amount` tokens to `recipient`.
     * @param recipient The address to which the tokens will be minted.
     * @param amount    The amount of tokens to mint.
     */
    function _mint(address recipient, uint256 amount) internal virtual;

    /**
     * @dev Burns `amount` tokens from `account`.
     * @param account The address from which the tokens will be burned.
     * @param amount  The amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal virtual;

    /* ============ Internal View/Pure Functions ============ */

    /// @dev Returns the current index of the M Token.
    function _currentMIndex() internal view returns (uint128) {
        return IMTokenLike(mToken()).currentIndex();
    }
}
