// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";

import { IMTokenLike } from "./interfaces/IMTokenLike.sol";
import { IMYieldToOne } from "./interfaces/IMYieldToOne.sol";

import { MExtension } from "./abstract/MExtension.sol";

/**
 * @title  ERC20 Token contract for wrapping M into a non-rebasing token with claimable yields.
 * @author M^0 Labs
 */
contract MYieldToOne is IMYieldToOne, MExtension {
    /* ============ Variables ============ */

    /// @inheritdoc IMYieldToOne
    address public immutable yieldRecipient;

    /// @inheritdoc IERC20
    mapping(address account => uint256 balance) public balanceOf;

    /// @inheritdoc IERC20
    uint256 public totalSupply;

    /* ============ Constructor ============ */

    /**
     * @dev   Constructs the M extension token with yield claimable by a single recipient.
     * @param mToken            The address of an M Token.
     * @param registrar         The address of a registrar.
     * @param yieldRecipient_   The address of an yield destination.
     */
    constructor(
        address mToken,
        address registrar,
        address yieldRecipient_
    ) MExtension("HALO USD", "HUSD", mToken, registrar) {
        if ((yieldRecipient = yieldRecipient_) == address(0)) revert ZeroYieldRecipient();
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMYieldToOne
    function claimYield() external returns (uint256) {
        uint256 yield_ = yield();

        if (yield_ == 0) revert NoYield();

        emit YieldClaimed(yield_);

        // NOTE: The behavior of `IMTokenLike.transfer` is known, so its return can be ignored.
        IMTokenLike(mToken).transfer(yieldRecipient, yield_);

        return yield_;
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IMYieldToOne
    function yield() public view returns (uint256) {
        unchecked {
            uint256 balance_ = _mBalanceOf(address(this));
            return balance_ > totalSupply ? balance_ - totalSupply : 0;
        }
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Mints `amount` tokens to `recipient`.
     * @param recipient The address whose account balance will be incremented.
     * @param amount    The present amount of tokens to mint.
     */
    function _mint(address recipient, uint256 amount) internal override {
        _revertIfInsufficientAmount(amount);
        _revertIfInvalidRecipient(recipient);

        unchecked {
            balanceOf[recipient] += amount;
            totalSupply += amount;
        }

        emit Transfer(address(0), recipient, amount);
    }

    /**
     * @dev   Burns `amount` tokens from `account`.
     * @param account The address whose account balance will be decremented.
     * @param amount  The present amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal override {
        _revertIfInsufficientAmount(amount);

        uint256 balance_ = balanceOf[account];

        if (balance_ < amount) revert InsufficientBalance(account, balance_, amount);

        unchecked {
            balanceOf[account] = balance_ - amount;
            totalSupply -= amount;
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
        _revertIfInvalidRecipient(recipient);

        emit Transfer(sender, recipient, amount);

        if (amount == 0) return;

        // NOTE: Can be `unchecked` because `_transfer` already checked for insufficient sender balance.
        unchecked {
            balanceOf[sender] -= amount;
            balanceOf[recipient] += amount;
        }
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the M Token balance of `account`.
     * @param  account The account being queried.
     * @return balance_ The M Token balance of the account.
     */
    function _mBalanceOf(address account) internal view returns (uint256) {
        return IMTokenLike(mToken).balanceOf(account);
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
