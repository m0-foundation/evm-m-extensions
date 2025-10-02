// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";

import { MYieldToOne } from "../yieldToOne/MYieldToOne.sol";

import { IMYieldToOne } from "../yieldToOne/IMYieldToOne.sol";

import { IMDualBackedYieldToOne } from "./IMDualBackedYieldToOne.sol";

import { ISwapFacility } from "../../swap/interfaces/ISwapFacility.sol";

import { IMTokenLike } from "../../interfaces/IMTokenLike.sol";

abstract contract MDualBackedYieldToOneStorageLayout {
    struct MDualBackedYieldToOneStorageStruct {
        address secondaryToken;
        uint8 secondaryDecimals;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.MDualBackedYieldToOne")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _M_DUAL_BACKED_YIELD_TO_ONE_STORAGE_LOCATION =
        0xcf2d6e9d1351d8d0083357b686a68d8501c3acb71aa4753ff0da62fd455c8900;

    function _getMDualBackedYieldToOneStorageLocation()
        internal
        pure
        returns (MDualBackedYieldToOneStorageStruct storage $)
    {
        assembly {
            $.slot := _M_DUAL_BACKED_YIELD_TO_ONE_STORAGE_LOCATION
        }
    }
}

/**
 * @title  MDualBackedYieldToOne
 * @notice Upgradeable ERC20 Token contract for wrapping M into a non-rebasing token
 *         with yield claimable by a single recipient and dual backing model.
 *         The dual backing model allows users to mint the extension token
 *         by depositing either M or a secondary ERC20 token.
 *         It assumes that both tokens are pegged 1:1.
 * @author M0 Labs
 */
contract MDualBackedYieldToOne is IMDualBackedYieldToOne, MDualBackedYieldToOneStorageLayout, MYieldToOne {
    /* ============ Variables ============ */

    /// @inheritdoc IMDualBackedYieldToOne
    uint8 public constant M_DECIMALS = 6;

    /* ============ Constructor ============ */

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs MDualBackedYieldToOne Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken       The address of $M token.
     * @param  swapFacility The address of Swap Facility.
     */
    constructor(address mToken, address swapFacility) MYieldToOne(mToken, swapFacility) {}

    /* ============ Initializer ============ */

    /**
     * @dev   Initializes the M extension token with dual backing model and yield claimable by a single recipient.
     * @param name                  The name of the token (e.g. "M Dual Backed Yield to One").
     * @param symbol                The symbol of the token (e.g. "MDBYO").
     * @param yieldRecipient        The address of a yield destination.
     * @param admin                 The address of an admin.
     * @param freezeManager         The address of a freeze manager.
     * @param yieldRecipientManager The address of a yield recipient setter.
     * @param secondaryToken_       The address of an ERC20 token contract to be used as secondary backing.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address secondaryToken_
    ) public virtual initializer {
        __MDualBackedYieldToOne_init(
            name,
            symbol,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            secondaryToken_
        );
    }

    /**
     * @dev   Initializes the MDualBackedYieldToOne token.
     * @param name                  The name of the token (e.g. "M Dual Backed Yield to One").
     * @param symbol                The symbol of the token (e.g. "MDBYO").
     * @param yieldRecipient        The address of a yield destination.
     * @param admin                 The address of an admin.
     * @param freezeManager         The address of a freeze manager.
     * @param yieldRecipientManager The address of a yield recipient setter.
     * @param secondaryToken_       The address of an ERC20 token contract to be used as secondary backing.
     */
    function __MDualBackedYieldToOne_init(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address secondaryToken_
    ) internal onlyInitializing {
        __MYieldToOne_init(name, symbol, yieldRecipient, admin, freezeManager, yieldRecipientManager);
        _setSecondaryToken(secondaryToken_);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMDualBackedYieldToOne
    function swapSecondary(address recipient, uint256 amount) external onlySwapFacility {
        _swapSecondary(recipient, amount);
    }

    /// @inheritdoc IMDualBackedYieldToOne
    function wrapSecondary(address recipient, uint256 amount) external onlySwapFacility {
        // NOTE: `msg.sender` is always SwapFacility contract.
        //       `ISwapFacility.msgSender()` is used to ensure that the original caller is passed to `_beforeWrap`.
        _wrapSecondary(ISwapFacility(msg.sender).msgSender(), recipient, amount);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IMYieldToOne
    function yield() public view override(IMYieldToOne, MYieldToOne) returns (uint256) {
        unchecked {
            uint256 mBalance_ = _mBalanceOf(address(this));
            uint256 mBacking_ = _mBacking();

            return mBalance_ > mBacking_ ? mBalance_ - mBacking_ : 0;
        }
    }

    /// @inheritdoc IMDualBackedYieldToOne
    function secondaryToken() public view returns (address) {
        return _getMDualBackedYieldToOneStorageLocation().secondaryToken;
    }

    /// @inheritdoc IMDualBackedYieldToOne
    function secondaryDecimals() public view returns (uint8) {
        return _getMDualBackedYieldToOneStorageLocation().secondaryDecimals;
    }

    /* ============ Hooks For Internal Interactive Functions ============ */

    /**
     * @dev   Hook called before unwrapping M Extension token.
     * @param account The account from which M Extension token is burned.
     * @param amount  The amount of M Extension token burned.
     */
    function _beforeUnwrap(address account, uint256 amount) internal view virtual override {
        super._beforeUnwrap(account, amount);

        uint256 mBacking_ = _mBacking();
        if (amount > mBacking_) revert InsufficientMBacking(amount, mBacking_);
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Sets the secondary token and fetches its decimals.
     * @param secondaryToken_ Address of an ERC20 token to be used as secondary backing.
     */
    function _setSecondaryToken(address secondaryToken_) internal {
        if (secondaryToken_ == address(0)) revert ZeroSecondaryToken();

        MDualBackedYieldToOneStorageStruct storage $ = _getMDualBackedYieldToOneStorageLocation();

        (bool success_, uint8 decimals_) = _tryGetTokenDecimals(secondaryToken_);

        if (success_) {
            $.secondaryDecimals = decimals_;
        } else {
            revert FailedToGetTokenDecimals(secondaryToken_);
        }

        $.secondaryToken = secondaryToken_;

        emit SecondaryTokenSet(secondaryToken_, decimals_);
    }

    /*
     * @notice Allows a M holder to swap M for the secondary token.
     * @dev    `amount` must be formatted in the secondary token's decimals.
     * @param  amount    Amount of secondary token to swap for M.
     * @param  recipient Address that will receive the secondary token.
     */
    function _swapSecondary(address recipient, uint256 amount) internal {
        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        uint256 mAmount_ = _toExtensionAmount(amount);

        // NOTE: Transfers M tokens from Swap Facility to this contract.
        IMTokenLike(mToken).transferFrom(msg.sender, address(this), mAmount_);

        address secondaryToken_ = secondaryToken();

        // NOTE: Transfers secondary tokens to recipient.
        //       Convert `mAmount_` to secondary token decimals since truncation may occur in `_toExtensionAmount()`.
        IERC20(secondaryToken_).transfer(recipient, _toSecondaryAmount(mAmount_));

        emit SwappedSecondaryToken(secondaryToken_, amount);
    }

    /*
     * @notice Mint extension tokens by depositing secondary token.
     * @dev    `amount` must be formatted in the secondary token's decimals.
     * @param  recipient Address that will receive the extension tokens.
     * @param  amount    Amount of tokens to mint.
     */
    function _wrapSecondary(address account, address recipient, uint256 amount) internal {
        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        // NOTE: MYieldToOne's `_beforeWrap` checks that `account` and `recipient` are not frozen.
        _beforeWrap(account, recipient, amount);

        address secondaryToken_ = secondaryToken();

        // NOTE: Transfers secondary tokens from SwapFacility to this contract (amount is in secondary token decimals).
        IERC20(secondaryToken_).transferFrom(msg.sender, address(this), amount);

        uint256 extensionAmount_ = _toExtensionAmount(amount);
        _mint(recipient, extensionAmount_);

        emit WrappedSecondaryToken(secondaryToken_, amount);
    }

    /* ============ Internal View Functions ============ */

    /// @dev Returns the current supply of M backing the extension token.
    function _mBacking() internal view returns (uint256) {
        uint256 totalSupply_ = totalSupply();

        uint256 secondaryTokenBalance_ = _toExtensionAmount(
            IERC20(_getMDualBackedYieldToOneStorageLocation().secondaryToken).balanceOf(address(this))
        );

        if (totalSupply_ < secondaryTokenBalance_) return 0;

        unchecked {
            return totalSupply_ - secondaryTokenBalance_;
        }
    }

    /**
     * @dev    Converts secondary token amount to extension token amount (6 decimals).
     * @param  amount Amount in secondary token decimals.
     * @return The normalized amount in 6 decimals.
     */
    function _toExtensionAmount(uint256 amount) internal view returns (uint256) {
        uint8 secondaryDecimals_ = secondaryDecimals();

        if (secondaryDecimals_ == M_DECIMALS) {
            return amount;
        } else if (secondaryDecimals_ < M_DECIMALS) {
            unchecked {
                return amount * 10 ** (M_DECIMALS - secondaryDecimals_);
            }
        } else {
            unchecked {
                return amount / 10 ** (secondaryDecimals_ - M_DECIMALS);
            }
        }
    }

    /**
     * @dev    Converts extension token amount to secondary token amount.
     * @param  amount Amount in extension token decimals.
     * @return Amount in secondary token decimals.
     */
    function _toSecondaryAmount(uint256 amount) internal view returns (uint256) {
        uint8 secondaryDecimals_ = secondaryDecimals();

        if (secondaryDecimals_ == M_DECIMALS) {
            return amount;
        } else if (secondaryDecimals_ > M_DECIMALS) {
            unchecked {
                return amount * 10 ** (secondaryDecimals_ - M_DECIMALS);
            }
        } else {
            unchecked {
                return amount / 10 ** (M_DECIMALS - secondaryDecimals_);
            }
        }
    }

    /**
     * @dev    Attempts to fetch the token decimals.
     * @param  token    Address of the token to query.
     * @return status   True if the call succeeded and returned a valid uint8 value.
     * @return decimals Number of decimals used by the token, or zero if the call failed.
     */
    function _tryGetTokenDecimals(address token) private view returns (bool status, uint8 decimals) {
        (bool success, bytes memory encodedDecimals) = token.staticcall(abi.encodeCall(IERC20.decimals, ()));

        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }

        return (false, 0);
    }
}
