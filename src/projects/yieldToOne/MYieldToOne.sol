// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.26;

import { ERC20ExtendedUpgradeable } from "../../../lib/common/src/ERC20ExtendedUpgradeable.sol";
import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";
import { IERC20Extended } from "../../../lib/common/src/interfaces/IERC20Extended.sol";

import { IMYieldToOne } from "./interfaces/IMYieldToOne.sol";

import { Freezable } from "../../components/freezable/Freezable.sol";
import { Pausable } from "../../components/pausable/Pausable.sol";
import { MExtension } from "../../MExtension.sol";

abstract contract MYieldToOneStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.MYieldToOne
    struct MYieldToOneStorageStruct {
        uint256 totalSupply;
        address yieldRecipient;
        mapping(address account => suint256 balance) balanceOf;
        // Shielded allowance storage — written by the shielded `approve` / `transferFrom`
        // overloads and read through the gated `allowance(address,address)` override below.
        // The inherited `ERC20ExtendedStorageStruct.allowance` slot is never written to
        // (the inherited `approve` / `permit` entry points revert) and remains zero forever.
        mapping(address account => mapping(address spender => suint256 allowance)) shieldedAllowance;
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
contract MYieldToOne is IMYieldToOne, MYieldToOneStorageLayout, MExtension, Freezable, Pausable {
    /* ============ Variables ============ */

    /// @inheritdoc IMYieldToOne
    bytes32 public constant YIELD_RECIPIENT_MANAGER_ROLE = keccak256("YIELD_RECIPIENT_MANAGER_ROLE");

    /* ============ Constructor ============ */

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs MYieldToOne Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken       The address of $M token.
     * @param  swapFacility The address of Swap Facility.
     */
    constructor(address mToken, address swapFacility) MExtension(mToken, swapFacility) {}

    /* ============ Initializer ============ */

    /**
     * @dev   Initializes the M extension token with yield claimable by a single recipient.
     * @param name                  The name of the token (e.g. "M Yield to One").
     * @param symbol                The symbol of the token (e.g. "MYO").
     * @param yieldRecipient_       The address of a yield destination.
     * @param admin                 The address of an admin.
     * @param freezeManager         The address of a freeze manager.
     * @param yieldRecipientManager The address of a yield recipient setter.
     * @param pauser                The address of a pauser.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient_,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address pauser
    ) public virtual initializer {
        __MYieldToOne_init(name, symbol, yieldRecipient_, admin, freezeManager, yieldRecipientManager, pauser);
    }

    /**
     * @notice Initializes the MYieldToOne token.
     * @param name                  The name of the token (e.g. "M Yield to One").
     * @param symbol                The symbol of the token (e.g. "MYO").
     * @param yieldRecipient_       The address of a yield destination.
     * @param admin                 The address of an admin.
     * @param freezeManager         The address of a freeze manager.
     * @param yieldRecipientManager The address of a yield recipient setter.
     * @param pauser                The address of a pauser.
     */
    function __MYieldToOne_init(
        string memory name,
        string memory symbol,
        address yieldRecipient_,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address pauser
    ) internal onlyInitializing {
        if (yieldRecipientManager == address(0)) revert ZeroYieldRecipientManager();
        if (admin == address(0)) revert ZeroAdmin();

        __MExtension_init(name, symbol);
        __Freezable_init(freezeManager);
        __Pausable_init(pauser);

        _setYieldRecipient(yieldRecipient_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMYieldToOne
    function claimYield() public virtual returns (uint256) {
        _beforeClaimYield();

        uint256 yield_ = yield();

        if (yield_ == 0) return 0;

        emit YieldClaimed(yield_);

        _mint(yieldRecipient(), yield_);

        return yield_;
    }

    /// @inheritdoc IMYieldToOne
    function setYieldRecipient(address account) external virtual onlyRole(YIELD_RECIPIENT_MANAGER_ROLE) {
        // Claim yield for the previous yield recipient.
        claimYield();

        _setYieldRecipient(account);
    }

    /* ============ Shielded ERC20 Entry Points ============ */

    /// @inheritdoc IMYieldToOne
    function transfer(address recipient, suint256 amount) external returns (bool) {
        _shieldedTransfer(msg.sender, recipient, amount);
        return true;
    }

    /// @inheritdoc IMYieldToOne
    function approve(address spender, suint256 amount) external returns (bool) {
        _shieldedApprove(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IMYieldToOne
    function transferFrom(address sender, address recipient, suint256 amount) external returns (bool) {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();
        suint256 spenderAllowance = $.shieldedAllowance[sender][msg.sender];

        // Infinite-allowance shortcut mirrors `ERC20ExtendedUpgradeable.transferFrom` (line 106):
        // a max-value allowance does not decrement. The cast to `uint256` is a control-flow
        // comparison only — it does not write back to storage and does not leak the shielded
        // value to any external observer.
        if (uint256(spenderAllowance) != type(uint256).max) {
            if (spenderAllowance < amount) revert IERC20Extended.InsufficientAllowance(msg.sender, 0, uint256(amount));

            unchecked {
                $.shieldedAllowance[sender][msg.sender] = spenderAllowance - amount;
            }
        }

        _shieldedTransfer(sender, recipient, amount);
        return true;
    }

    /* ============ Inherited IERC20 / IERC20Extended Entry Points (Reverted) ============ */
    // The inherited unshielded `transfer` / `transferFrom` / `approve` / `permit` entry points
    // remain in the ABI for IERC20 compatibility but always revert. Callers must use the
    // `suint256`-typed overloads above. Marking these `pure` because they touch no state.

    /// @inheritdoc IERC20
    function transfer(
        address /* recipient */,
        uint256 /* amount */
    ) external pure override(ERC20ExtendedUpgradeable, IERC20) returns (bool) {
        revert UseShieldedTransfer();
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address /* sender */,
        address /* recipient */,
        uint256 /* amount */
    ) external pure override(ERC20ExtendedUpgradeable, IERC20) returns (bool) {
        revert UseShieldedTransfer();
    }

    /// @inheritdoc IERC20
    function approve(
        address /* spender */,
        uint256 /* amount */
    ) external pure override(ERC20ExtendedUpgradeable, IERC20) returns (bool) {
        revert UseShieldedApprove();
    }

    /// @inheritdoc IERC20Extended
    function permit(
        address /* owner */,
        address /* spender */,
        uint256 /* value */,
        uint256 /* deadline */,
        uint8 /* v */,
        bytes32 /* r */,
        bytes32 /* s */
    ) external pure override(ERC20ExtendedUpgradeable, IERC20Extended) {
        revert UseShieldedApprove();
    }

    /// @inheritdoc IERC20Extended
    function permit(
        address /* owner */,
        address /* spender */,
        uint256 /* value */,
        uint256 /* deadline */,
        bytes memory /* signature */
    ) external pure override(ERC20ExtendedUpgradeable, IERC20Extended) {
        revert UseShieldedApprove();
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC20
    /// @dev Shielded read. Allowed callers: `account` itself (via a Seismic signed read,
    ///      TxSeismic type 0x4A — plain `eth_call` zeroes `msg.sender` and reverts), or the
    ///      `swapFacility` immutable. The SwapFacility exemption lets shared M0 infra
    ///      observe extension balances for operational paths it controls; the holder's
    ///      balance is not exposed to arbitrary callers.
    function balanceOf(address account) public view override returns (uint256) {
        if (msg.sender != account && msg.sender != swapFacility) revert Unauthorized();
        return uint256(_getMYieldToOneStorageLocation().balanceOf[account]);
    }

    /// @inheritdoc IERC20
    function totalSupply() public view returns (uint256) {
        return _getMYieldToOneStorageLocation().totalSupply;
    }

    /// @inheritdoc IERC20
    /// @dev Shielded read. Requires `msg.sender == owner` or `msg.sender == spender`; external
    ///      clients must use a Seismic signed read (TxSeismic type 0x4A). The inherited
    ///      unshielded `ERC20ExtendedStorageStruct.allowance` slot is no longer written to
    ///      (the IERC20 `approve` / `permit` entry points revert), so this gated view is the
    ///      sole readable allowance source.
    function allowance(
        address owner,
        address spender
    ) public view override(ERC20ExtendedUpgradeable, IERC20) returns (uint256) {
        if (msg.sender != owner && msg.sender != spender) revert Unauthorized();
        return uint256(_getMYieldToOneStorageLocation().shieldedAllowance[owner][spender]);
    }

    /// @inheritdoc IMYieldToOne
    function yield() public view virtual returns (uint256) {
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
    function _beforeApprove(address account, address spender, uint256 /* amount */) internal view virtual override {
        FreezableStorageStruct storage $ = _getFreezableStorageLocation();

        _revertIfFrozen($, account);
        _revertIfFrozen($, spender);
    }

    /**
     * @dev    Hooks called before wrapping M into M Extension token.
     * @param  account   The account from which M is deposited.
     * @param  recipient The account receiving the minted M Extension token.
     */
    function _beforeWrap(address account, address recipient, uint256 /* amount */) internal view virtual override {
        _requireNotPaused();
        FreezableStorageStruct storage $ = _getFreezableStorageLocation();

        _revertIfFrozen($, account);
        _revertIfFrozen($, recipient);
    }

    /**
     * @dev   Hook called before unwrapping M Extension token.
     * @param account The account from which M Extension token is burned.
     */
    function _beforeUnwrap(address account, uint256 /* amount */) internal view virtual override {
        _requireNotPaused();
        _revertIfFrozen(_getFreezableStorageLocation(), account);
    }

    /**
     * @dev   Hook called before transferring M Extension token.
     * @param sender    The address from which the tokens are being transferred.
     * @param recipient The address to which the tokens are being transferred.
     */
    function _beforeTransfer(address sender, address recipient, uint256 /* amount */) internal view virtual override {
        _requireNotPaused();
        FreezableStorageStruct storage $ = _getFreezableStorageLocation();

        _revertIfFrozen($, msg.sender);

        _revertIfFrozen($, sender);
        _revertIfFrozen($, recipient);
    }

    /**
     * @dev   Hook called before claiming yield from the M Extension token. To be overridden in derived extensions.
     */
    function _beforeClaimYield() internal view virtual {}

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Mints `amount` tokens to `recipient`.
     * @param recipient The address whose account balance will be incremented.
     * @param amount    The present amount of tokens to mint.`
     */
    function _mint(address recipient, uint256 amount) internal override {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        // NOTE: Can be `unchecked` because the max amount of $M is never greater than `type(uint240).max`.
        unchecked {
            $.balanceOf[recipient] = $.balanceOf[recipient] + suint256(amount);
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

        // NOTE: Can be `unchecked` because `_revertIfInsufficientBalance` is used in MExtension.
        unchecked {
            $.balanceOf[account] = $.balanceOf[account] - suint256(amount);
            $.totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev   Internal balance update used by both the inherited (now-unreachable from outside)
     *        and the shielded transfer paths, and by `MYieldToOneForcedTransfer._forceTransfer`.
     *        Casts the public `uint256` to the shielded storage type at the boundary.
     */
    function _update(address sender, address recipient, uint256 amount) internal override {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        // NOTE: Can be `unchecked` because `_revertIfInsufficientBalance` for `sender` runs
        // before this call (in `MExtension._transfer` and in `_shieldedTransfer`).
        unchecked {
            $.balanceOf[sender] = $.balanceOf[sender] - suint256(amount);
            $.balanceOf[recipient] = $.balanceOf[recipient] + suint256(amount);
        }
    }

    /**
     * @dev   Shielded transfer pipeline. Mirrors the structure of `MExtension._transfer` but
     *        entry-points to the same `_update` primitive via a `suint256 → uint256` bridge.
     *        Reuses the existing `_beforeTransfer` hook for freeze/pause checks.
     * @dev   Reverts with `InsufficientBalance(account, 0, amount)` — zeroing the `balance`
     *        field so the revert payload does not leak the shielded balance value, matching
     *        the precedent set by `_revertIfInsufficientBalance`.
     */
    function _shieldedTransfer(address sender, address recipient, suint256 amount) internal {
        uint256 amount_ = uint256(amount);

        _revertIfInvalidRecipient(recipient);
        _beforeTransfer(sender, recipient, amount_);

        emit Transfer(sender, recipient, amount_);

        if (amount_ == 0) return;

        if (_getMYieldToOneStorageLocation().balanceOf[sender] < amount) {
            revert InsufficientBalance(sender, 0, amount_);
        }

        _update(sender, recipient, amount_);
    }

    /**
     * @dev   Shielded approve pipeline. Writes to `MYieldToOneStorageStruct.shieldedAllowance`
     *        in this contract's own ERC-7201 slot; the inherited
     *        `ERC20ExtendedStorageStruct.allowance` slot is never touched. Reuses the
     *        existing `_beforeApprove` hook for freeze checks.
     */
    function _shieldedApprove(address account, address spender, suint256 amount) internal {
        uint256 amount_ = uint256(amount);

        _beforeApprove(account, spender, amount_);

        _getMYieldToOneStorageLocation().shieldedAllowance[account][spender] = amount;

        emit Approval(account, spender, amount_);
    }

    /**
     * @dev   Shielded balance accessor for internal callers. Bypasses the public `balanceOf`
     *        gate. Used by `_revertIfInsufficientBalance` (still reached via the unwrap path
     *        in `MExtension._unwrap`) and available for any future shielded internal logic.
     *        Returns the raw `suint256` so comparisons stay shielded.
     */
    function _balanceOf(address account) internal view returns (suint256) {
        return _getMYieldToOneStorageLocation().balanceOf[account];
    }

    /**
     * @dev   Overrides `MExtension._revertIfInsufficientBalance` to compare in shielded space and
     *        revert with `balance = 0` so the holder's actual balance does not leak via the revert
     *        payload. The `IMExtension.InsufficientBalance` error shape is preserved (no interface
     *        change) — only the `balance` field is zeroed at the call site.
     */
    function _revertIfInsufficientBalance(address account, uint256 amount) internal view override {
        if (_balanceOf(account) < suint256(amount)) revert InsufficientBalance(account, 0, amount);
    }

    /**
     * @dev Sets the yield recipient.
     * @param yieldRecipient_ The address of the new yield recipient.
     */
    function _setYieldRecipient(address yieldRecipient_) internal {
        if (yieldRecipient_ == address(0)) revert ZeroYieldRecipient();

        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        if (yieldRecipient_ == $.yieldRecipient) return;

        $.yieldRecipient = yieldRecipient_;

        emit YieldRecipientSet(yieldRecipient_);
    }
}
