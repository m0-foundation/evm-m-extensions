// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { ERC20ExtendedUpgradeable } from "../lib/common/src/ERC20ExtendedUpgradeable.sol";

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";

import { IMTokenLike } from "./interfaces/IMTokenLike.sol";
import { IMExtension } from "./interfaces/IMExtension.sol";
import { ISwapFacility } from "./swap/interfaces/ISwapFacility.sol";

/**
 * @title  MExtension
 * @notice Upgradeable ERC20 Token contract for wrapping M into a non-rebasing token.
 * @author M0 Labs
 */
abstract contract MExtension is IMExtension, ERC20ExtendedUpgradeable {
    /* ============ Variables ============ */

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    /// @inheritdoc IMExtension
    address public immutable mToken;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    /// @inheritdoc IMExtension
    address public immutable swapFacility;

    /* ============ Modifiers ============ */

    /// @dev Modifier to check if caller is SwapFacility.
    modifier onlySwapFacility() {
        if (msg.sender != swapFacility) revert NotSwapFacility();
        _;
    }

    /* ============ Constructor ============ */

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs MExtension Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken_       The address of $M token.
     * @param  swapFacility_ The address of Swap Facility.
     */
    constructor(address mToken_, address swapFacility_) {
        _disableInitializers();

        if ((mToken = mToken_) == address(0)) revert ZeroMToken();
        if ((swapFacility = swapFacility_) == address(0)) revert ZeroSwapFacility();
    }

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the generic M extension token.
     * @param name          The name of the token (e.g. "HALO USD").
     * @param symbol        The symbol of the token (e.g. "HUSD").
     */
    function __MExtension_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC20ExtendedUpgradeable_init(name, symbol, 6);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMExtension
    function wrap(address recipient, uint256 amount) external onlySwapFacility {
        // NOTE: `msg.sender` is always SwapFacility contract.
        //       `ISwapFacility.msgSender()` is used to ensure that the original caller is passed to `_beforeWrap`.
        _wrap(ISwapFacility(msg.sender).msgSender(), recipient, amount);
    }

    /// @inheritdoc IMExtension
    function unwrap(address /* recipient */, uint256 amount) external onlySwapFacility {
        // NOTE: `msg.sender` is always SwapFacility contract.
        //       `ISwapFacility.msgSender()` is used to ensure that the original caller is passed to `_beforeUnwrap`.
        // NOTE: `recipient` is not used in this function as the $M is always sent to SwapFacility contract.
        _unwrap(ISwapFacility(msg.sender).msgSender(), amount);
    }

    /// @inheritdoc IMExtension
    function enableEarning() external virtual {
        if (isEarningEnabled()) revert EarningIsEnabled();

        emit EarningEnabled(currentIndex());

        IMTokenLike(mToken).startEarning();
    }

    /// @inheritdoc IMExtension
    function disableEarning() external virtual {
        if (!isEarningEnabled()) revert EarningIsDisabled();

        emit EarningDisabled(currentIndex());

        IMTokenLike(mToken).stopEarning(address(this));
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IMExtension
    function currentIndex() public view virtual returns (uint128) {
        return IMTokenLike(mToken).currentIndex();
    }

    /// @inheritdoc IMExtension
    function isEarningEnabled() public view virtual returns (bool) {
        return IMTokenLike(mToken).isEarning(address(this));
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256);

    /* ============ Hooks For Internal Interactive Functions ============ */

    /**
     * @dev   Hook called before approval of M Extension token.
     * @param account   The sender's address.
     * @param spender   The spender address.
     * @param amount    The amount to be approved.
     */
    function _beforeApprove(address account, address spender, uint256 amount) internal virtual {}

    /**
     * @dev    Hook called before wrapping M into M Extension token.
     * @param  account   The account from which M is deposited.
     * @param  recipient The account receiving the minted M Extension token.
     * @param  amount    The amount of M deposited.
     */
    function _beforeWrap(address account, address recipient, uint256 amount) internal virtual {}

    /**
     * @dev   Hook called before unwrapping M Extension token.
     * @param account   The account from which M Extension token is burned.
     * @param amount    The amount of M Extension token burned.
     */
    function _beforeUnwrap(address account, uint256 amount) internal virtual {}

    /**
     * @dev   Hook called before transferring M Extension token.
     * @param sender    The sender's address.
     * @param recipient The recipient's address.
     * @param amount    The amount to be transferred.
     */
    function _beforeTransfer(address sender, address recipient, uint256 amount) internal virtual {}

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev Approve `spender` to spend `amount` of tokens from `account`.
     * @param account The address approving the allowance.
     * @param spender The address approved to spend the tokens.
     * @param amount  The amount of tokens being approved for spending.
     */
    function _approve(address account, address spender, uint256 amount) internal override {
        // NOTE: Add extension-specific checks before approval.
        _beforeApprove(account, spender, amount);

        super._approve(account, spender, amount);
    }

    /**
     * @dev    Wraps `amount` M from `account` into M Extension for `recipient`.
     * @param  account   The original caller of SwapFacility functions.
     * @param  recipient The account receiving the minted M Extension token.
     * @param  amount    The amount of M deposited.
     */
    function _wrap(address account, address recipient, uint256 amount) internal {
        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        // NOTE: Add extension-specific checks before wrapping.
        _beforeWrap(account, recipient, amount);

        // NOTE: `msg.sender` is always SwapFacility contract.
        // NOTE: The behavior of `IMTokenLike.transferFrom` is known, so its return can be ignored.
        IMTokenLike(mToken).transferFrom(msg.sender, address(this), amount);

        // NOTE: This method is overridden by the inheriting M Extension contract.
        // NOTE: Mints precise amount of $M Extension token to `recipient`.
        //       Option 1: $M transfer from an $M earner to another $M earner ($M Extension in earning state): rounds up → rounds up,
        //                 0, 1, or XX extra wei may be locked in M Extension compared to the minted amount of $M Extension token.
        //       Option 2: $M transfer from an $M non-earner to an $M earner ($M Extension in earning state): precise $M transfer → rounds down,
        //                 0, -1, or -XX wei may be locked in $M Extension compared to the minted amount of $M Extension token.
        //
        _mint(recipient, amount);
    }

    /**
     * @dev    Unwraps `amount` M Extension token from `account` into $M and transfers to SwapFacility.
     * @param  account   The original caller of SwapFacility functions.
     * @param  amount    The amount of M Extension token burned.
     */
    function _unwrap(address account, uint256 amount) internal {
        _revertIfInsufficientAmount(amount);

        // NOTE: Add extension-specific checks before unwrapping.
        _beforeUnwrap(account, amount);

        _revertIfInsufficientBalance(msg.sender, balanceOf(msg.sender), amount);

        // NOTE: This method will be overridden by the inheriting M Extension contract.
        // NOTE: Computes the actual decrease in the $M balance of the $M Extension contract.
        //       Option 1: $M transfer from an $M earner ($M Extension in earning state) to another $M earner: round up → rounds up.
        //       Option 2: $M transfer from an $M earner ($M Extension in earning state) to an $M non-earner: round up → precise $M transfer.
        //       In both cases, 0, 1, or XX extra wei may be deducted from the $M Extension contract's $M balance compared to the burned amount of $M Extension token.
        // NOTE: Always burn from SwapFacility as it is the only contract that can call this function.
        _burn(msg.sender, amount);

        // NOTE: The behavior of `IMTokenLike.transfer` is known, so its return can be ignored.
        // NOTE: `msg.sender` is always SwapFacility contract.
        IMTokenLike(mToken).transfer(msg.sender, amount);
    }

    /**
     * @dev   Mints `amount` tokens to `recipient`.
     * @param recipient The address to which the tokens will be minted.
     * @param amount    The amount of tokens to mint.
     */
    function _mint(address recipient, uint256 amount) internal virtual;

    /**
     * @dev   Burns `amount` tokens from `account`.
     * @param account The address from which the tokens will be burned.
     * @param amount  The amount of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal virtual;

    /**
     * @dev   Internal ERC20 transfer function that needs to be implemented by the inheriting contract.
     * @param sender    The sender's address.
     * @param recipient The recipient's address.
     * @param amount    The amount to be transferred.
     */
    function _update(address sender, address recipient, uint256 amount) internal virtual;

    /**
     * @dev   Internal ERC20 transfer function that needs to be implemented by the inheriting contract.
     * @param sender    The sender's address.
     * @param recipient The recipient's address.
     * @param amount    The amount to be transferred.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        _revertIfInvalidRecipient(recipient);

        // NOTE: Add extension-specific checks before transfers.
        _beforeTransfer(sender, recipient, amount);

        emit Transfer(sender, recipient, amount);

        if (amount == 0) return;

        _revertIfInsufficientBalance(sender, balanceOf(sender), amount);

        // NOTE: This method will be overridden by the inheriting M Extension contract.
        _update(sender, recipient, amount);
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the M Token balance of `account`.
     * @param  account The account being queried.
     * @return balance The M Token balance of the account.
     */
    function _mBalanceOf(address account) internal view returns (uint256) {
        return IMTokenLike(mToken).balanceOf(account);
    }

    /**
     * @dev   Reverts if `recipient` is address(0).
     * @param recipient Address of a recipient.
     */
    function _revertIfInvalidRecipient(address recipient) internal pure {
        if (recipient == address(0)) revert InvalidRecipient(recipient);
    }

    /**
     * @dev   Reverts if `amount` is equal to 0.
     * @param amount Amount of token.
     */
    function _revertIfInsufficientAmount(uint256 amount) internal pure {
        if (amount == 0) revert InsufficientAmount(amount);
    }

    /**
     * @dev   Reverts if `account` balance is below `amount`.
     * @param account Address of an account.
     * @param balance Balance of an account.
     * @param amount  Amount to transfer or burn.
     */
    function _revertIfInsufficientBalance(address account, uint256 balance, uint256 amount) internal pure {
        if (balance < amount) revert InsufficientBalance(account, balance, amount);
    }
}
