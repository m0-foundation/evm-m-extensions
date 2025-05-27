// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";

import { IMTokenLike } from "./interfaces/IMTokenLike.sol";
import { IMYieldToOne } from "./interfaces/IMYieldToOne.sol";

import { Blacklistable } from "./abstract/components/Blacklistable.sol";

import { MExtension } from "./abstract/MExtension.sol";

abstract contract MYieldToOneStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.MYieldToOne
    struct MYieldToOneStorageStruct {
        mapping(address account => uint256 balance) balanceOf;
        uint256 totalSupply;
        address yieldRecipient;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.MYieldToOne")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _M_YIELD_TO_ONE_STORAGE_LOCATION =
        0xee2f6fc7e2e5879b17985791e0d12536cba689bda43c77b8911497248f4af100;

    function _getMYieldToOneStorageLocation() internal pure returns (MYieldToOneStorageStruct storage $) {
        assembly {
            $.slot := _M_YIELD_TO_ONE_STORAGE_LOCATION
        }
    }
}

/**
 * @title  MYieldToOne
 * @notice Upgradeable ERC20 Token contract for wrapping M into a non-rebasing token
 *         with yield claimable by a single recipient.
 * @author M0 Labs
 */
contract MYieldToOne is IMYieldToOne, MYieldToOneStorageLayout, MExtension, Blacklistable {
    /* ============ Variables ============ */

    /// @inheritdoc IMYieldToOne
    bytes32 public constant YIELD_RECIPIENT_MANAGER_ROLE = keccak256("YIELD_RECIPIENT_MANAGER_ROLE");

    /* ============ Initializer ============ */

    /**
     * @dev   Initializes the M extension token with yield claimable by a single recipient.
     * @param name                   The name of the token (e.g. "M Yield to One").
     * @param symbol                 The symbol of the token (e.g. "MYO").
     * @param mToken                 The address of the M Token.
     * @param yieldRecipient_        The address of an yield destination.
     * @param defaultAdmin           The address of a default admin.
     * @param blacklistManager       The address of a blacklist manager.
     * @param yieldRecipientManager  The address of a yield recipient setter.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address mToken,
        address yieldRecipient_,
        address defaultAdmin,
        address blacklistManager,
        address yieldRecipientManager
    ) public initializer {
        if (yieldRecipientManager == address(0)) revert ZeroYieldRecipientManager();
        if (defaultAdmin == address(0)) revert ZeroDefaultAdmin();

        __MExtension_init(name, symbol, mToken);
        __Blacklistable_init(blacklistManager);

        _setYieldRecipient(yieldRecipient_);

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMYieldToOne
    function claimYield() external returns (uint256) {
        uint256 yield_ = yield();

        if (yield_ == 0) revert NoYield();

        emit YieldClaimed(yield_);

        // NOTE: The behavior of `IMTokenLike.transfer` is known, so its return can be ignored.
        IMTokenLike(mToken()).transfer(yieldRecipient(), yield_);

        return yield_;
    }

    /// @inheritdoc IMYieldToOne
    function setYieldRecipient(address account) external onlyRole(YIELD_RECIPIENT_MANAGER_ROLE) {
        _setYieldRecipient(account);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC20
    function balanceOf(address account) public view returns (uint256) {
        return _getMYieldToOneStorageLocation().balanceOf[account];
    }

    /// @inheritdoc IERC20
    function totalSupply() public view returns (uint256) {
        return _getMYieldToOneStorageLocation().totalSupply;
    }

    /// @inheritdoc IMYieldToOne
    function yield() public view returns (uint256) {
        unchecked {
            uint256 balance_ = _mBalanceOf(address(this));
            uint256 totalSupply_ = totalSupply();

            return balance_ > totalSupply_ ? balance_ - totalSupply_ : 0;
        }
    }

    /// @inheritdoc IMYieldToOne
    function yieldRecipient() public view returns (address) {
        return _getMYieldToOneStorageLocation().yieldRecipient;
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev Approve `spender` to spend `amount` of tokens from `account`.
     * @param account The address approving the allowance.
     * @param spender The address approved to spend the tokens.
     * @param amount  The amount of tokens being approved for spending.
     */
    function _approve(address account, address spender, uint256 amount) internal override {
        BlacklistableStorageStruct storage $ = _getBlacklistableStorageLocation();

        _revertIfBlacklisted($, account);
        _revertIfBlacklisted($, spender);

        super._approve(account, spender, amount);
    }

    /**
     * @dev    Hooks called before wrapping M into M Extension token.
     * @param  account   The account from which M is deposited.
     * @param  recipient The account receiving the minted M Extension token.
     */
    function _beforeWrap(address account, address recipient, uint256 /* amount */) internal view override {
        BlacklistableStorageStruct storage $ = _getBlacklistableStorageLocation();

        _revertIfBlacklisted($, account);
        _revertIfBlacklisted($, recipient);
    }

    /**
     * @dev   Mints `amount` tokens to `recipient`.
     * @param recipient The address whose account balance will be incremented.
     * @param amount    The present amount of tokens to mint.
     */
    function _mint(address recipient, uint256 amount) internal override {
        _revertIfInsufficientAmount(amount);
        _revertIfInvalidRecipient(recipient);

        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        unchecked {
            $.balanceOf[recipient] += amount;
            $.totalSupply += amount;
        }

        emit Transfer(address(0), recipient, amount);
    }

    /**
     * @dev   Hook called before unwrapping M Extension token.
     * @param account   The account from which M Extension token is burned.
     * @param recipient The account receiving the withdrawn M.
     */
    function _beforeUnwrap(address account, address recipient, uint256 /* amount */) internal view override {
        BlacklistableStorageStruct storage $ = _getBlacklistableStorageLocation();

        _revertIfBlacklisted($, account);
        _revertIfBlacklisted($, recipient);
    }

    /**
     * @dev   Burns `amount` tokens from `account`.
     * @param account The address whose account balance will be decremented.
     * @param amount  The present amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal override {
        _revertIfInsufficientAmount(amount);

        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();
        uint256 balance_ = $.balanceOf[account];

        if (balance_ < amount) revert InsufficientBalance(account, balance_, amount);

        unchecked {
            $.balanceOf[account] = balance_ - amount;
            $.totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev   Internal ERC20 transfer function that needs to be implemented by the inheriting contract.
     * @param sender    The sender's address.
     * @param recipient The recipient's address.
     * @param amount    The amount to be transferred.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        BlacklistableStorageStruct storage blacklistableStorage = _getBlacklistableStorageLocation();

        _revertIfBlacklisted(blacklistableStorage, msg.sender);
        _revertIfBlacklisted(blacklistableStorage, sender);
        _revertIfBlacklisted(blacklistableStorage, recipient);
        _revertIfInvalidRecipient(recipient);

        emit Transfer(sender, recipient, amount);

        if (amount == 0) return;

        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();
        uint256 balance_ = $.balanceOf[sender];

        if (balance_ < amount) revert InsufficientBalance(sender, balance_, amount);

        // NOTE: Can be `unchecked` because we check for insufficient sender balance above.
        unchecked {
            $.balanceOf[sender] = balance_ - amount;
            $.balanceOf[recipient] += amount;
        }
    }

    /**
     * @dev Sets the yield recipient.
     * @param account The address of the new yield recipient.
     */
    function _setYieldRecipient(address account) internal {
        if (account == address(0)) revert ZeroYieldRecipient();

        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        if (account == $.yieldRecipient) return;

        $.yieldRecipient = account;

        emit YieldRecipientSet(account);
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the M Token balance of `account`.
     * @param  account The account being queried.
     * @return balance_ The M Token balance of the account.
     */
    function _mBalanceOf(address account) internal view returns (uint256) {
        return IMTokenLike(mToken()).balanceOf(account);
    }

    /**
     * @dev   Reverts if `amount` is equal to 0.
     * @param amount Amount of token.
     */
    function _revertIfInsufficientAmount(uint256 amount) internal pure {
        if (amount == 0) revert InsufficientAmount(amount);
    }

    /**
     * @dev   Reverts if `account` is address(0).
     * @param account Address of an account.
     */
    function _revertIfInvalidRecipient(address account) internal pure {
        if (account == address(0)) revert InvalidRecipient(account);
    }
}
