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
     * @param swapFacility           The address of the Swap Facility.
     * @param yieldRecipient_        The address of an yield destination.
     * @param defaultAdmin           The address of a default admin.
     * @param blacklistManager       The address of a blacklist manager.
     * @param yieldRecipientManager  The address of a yield recipient setter.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address mToken,
        address swapFacility,
        address yieldRecipient_,
        address defaultAdmin,
        address blacklistManager,
        address yieldRecipientManager
    ) public initializer {
        if (yieldRecipientManager == address(0)) revert ZeroYieldRecipientManager();
        if (defaultAdmin == address(0)) revert ZeroDefaultAdmin();

        __MExtension_init(name, symbol, mToken, swapFacility);
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

        _mint(yieldRecipient(), yield_);

        return yield_;
    }

    /// @inheritdoc IMYieldToOne
    function setYieldRecipient(address account) external onlyRole(YIELD_RECIPIENT_MANAGER_ROLE) {
        _setYieldRecipient(account);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC20
    function balanceOf(address account) public view override returns (uint256) {
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

    /* ============ Hooks For Internal Interactive Functions ============ */

    /**
     * @dev    Hooks called before approval of M extension spend.
     * @param  account The account from which M is deposited.
     * @param  spender The account spending M Extension token.
     */
    function _beforeApprove(address account, address spender, uint256 /* amount */) internal view override {
        BlacklistableStorageStruct storage $ = _getBlacklistableStorageLocation();

        _revertIfBlacklisted($, account);
        _revertIfBlacklisted($, spender);
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
     * @dev   Hook called before unwrapping M Extension token.
     * @param account The account from which M Extension token is burned.
     */
    function _beforeUnwrap(address account, uint256 /* amount */) internal view override {
        _revertIfBlacklisted(_getBlacklistableStorageLocation(), account);
    }

    /**
     * @dev   Hook called before transferring M Extension token.
     * @param sender    The address from which the tokens are being transferred.
     * @param recipient The address to which the tokens are being transferred.
     */
    function _beforeTransfer(address sender, address recipient, uint256 /* amount */) internal view override {
        BlacklistableStorageStruct storage $ = _getBlacklistableStorageLocation();

        _revertIfBlacklisted($, msg.sender);

        _revertIfBlacklisted($, sender);
        _revertIfBlacklisted($, recipient);
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Mints `amount` tokens to `recipient`.
     * @param recipient The address whose account balance will be incremented.
     * @param amount    The present amount of tokens to mint.
     */
    function _mint(address recipient, uint256 amount) internal override {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        unchecked {
            $.balanceOf[recipient] += amount;
            $.totalSupply += amount;
        }

        emit Transfer(address(0), recipient, amount);
    }

    /**
     * @dev   Burns `amount` tokens from `account`.
     * @param account The address whose account balance will be decremented.
     * @param amount  The present amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal override {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();
        uint256 balance_ = $.balanceOf[account];

        _revertIfInsufficientBalance(account, balance_, amount);

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
    function _update(address sender, address recipient, uint256 amount) internal override {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        // NOTE: Can be `unchecked` because we check for insufficient sender balance above.
        unchecked {
            $.balanceOf[sender] -= amount;
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
}
