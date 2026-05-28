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
        // slot 0 — total supply (public, unshielded).
        uint256 totalSupply;
        // slot 1 — yield destination (public).
        address yieldRecipient;
        // slot 2 — shielded balances keyed by holder.
        mapping(address account => suint256 balance) balanceOf;
        // slot 3 — shielded allowance storage — written by BOTH the shielded `approve` / `transferFrom`
        // overloads and the native, infra-gated `approve` / `transferFrom` overloads (which cast at
        // the ABI boundary), and read through the gated `allowance(address,address)` override below.
        // The inherited `ERC20ExtendedStorageStruct.allowance` slot is never written to (native
        // `approve` writes here instead; `permit` reverts) and remains zero forever.
        mapping(address account => mapping(address spender => suint256 allowance)) shieldedAllowance;
        // slot 4 — infra allowlist — admin-curated set of trusted M0 infrastructure contracts (the
        // `swapFacility` immutable is additionally exempt without occupying a slot here). An
        // allowlisted address may use the native `uint256` `approve` (as spender) / `transferFrom`
        // (as caller) paths and may read any holder's cleartext `balanceOf`. Read via `_isInfra`.
        mapping(address account => bool isAllowlisted) allowlist;
        // === appended for encrypted Transfer events ===
        // slot 5 — recipient public-key registry. Each holder MAY register a compressed
        // (33-byte) secp256k1 public key via `registerPublicKey`; the contract uses it as the
        // ECDH peer when encrypting `Transfer` amounts to that holder. An unregistered
        // recipient triggers the empty-ciphertext fallback in `_emitEncryptedTransfer`.
        mapping(address account => bytes publicKey) publicKeys;
        // slot 6 — contract public key (plain bytes, readable by anyone). Off-chain
        // decryption clients fetch this to perform ECDH with their own private key.
        bytes _contractPublicKey;
        // slot 7 — contract private key (shielded). Set once via `setContractKey` (which MUST
        // be sent as `TxSeismic` type `0x4A` so the key is encrypted in calldata). Used as
        // the local ECDH input; never returned from any view or exposed in calldata.
        sbytes32 contractPrivateKey;
        // slot 8 — monotonic counter feeding the per-emit AES-GCM nonce. Pre-incremented
        // before every encrypted emit, so the first emitted nonce uses counter value 1 and
        // no two encrypted emits ever reuse a nonce under the same key — a deliberate
        // departure from the tutorial's `keccak256(from, to, block.number)` formulation.
        uint256 encryptedEventNonce;
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

    /* ============ Allowlist Management ============ */

    /// @inheritdoc IMYieldToOne
    function setAllowlisted(address account, bool status) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAllowlisted(account, status);
    }

    /// @inheritdoc IMYieldToOne
    function setAllowlisted(address[] calldata accounts, bool status) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < accounts.length; ++i) {
            _setAllowlisted(accounts[i], status);
        }
    }

    /* ============ Encrypted-Event Keypair Management ============ */

    /// @inheritdoc IMYieldToOne
    /// @dev OPERATIONAL REQUIREMENT (not enforceable from Solidity): the admin MUST send
    ///      this call as a Seismic `TxSeismic` transaction (type `0x4A`), so the private
    ///      key is encrypted in the calldata layer. If sent as a plain transaction the
    ///      private key is recoverable from the mempool / public tx history, defeating the
    ///      purpose of the shielded slot. See `docs/seismic-question-encrypted-events-ux.md`.
    /// @dev Open question filed with Seismic: whether the `bytes32($.contractPrivateKey)
    ///      != bytes32(0)` one-shot guard reads cleanly from shielded storage without
    ///      leaking the value, and whether `sbytes32(0)` is the canonical unset sentinel.
    ///      See `docs/seismic-question-encrypted-events-ux.md` (questions §2).
    function setContractKey(
        sbytes32 privateKey,
        bytes calldata publicKey
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        if (publicKey.length != 33) revert InvalidPublicKeyLength();

        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        // One-shot guard. The cast to `bytes32` is a control-flow comparison only — it
        // mirrors the infinite-allowance shortcut in `_spendAllowanceAndTransfer` and does
        // not write the shielded value back to storage.
        if (bytes32($.contractPrivateKey) != bytes32(0)) revert ContractKeyAlreadySet();

        $.contractPrivateKey = privateKey;
        $._contractPublicKey = publicKey;

        emit ContractKeySet(publicKey);
    }

    /// @inheritdoc IMYieldToOne
    function registerPublicKey(bytes calldata publicKey) external virtual {
        if (publicKey.length != 33) revert InvalidPublicKeyLength();

        _getMYieldToOneStorageLocation().publicKeys[msg.sender] = publicKey;

        emit PublicKeyRegistered(msg.sender);
    }

    /* ============ Shielded ERC20 Entry Points ============ */

    /// @inheritdoc IMYieldToOne
    function transfer(address recipient, suint256 amount) external returns (bool) {
        // User-to-user path: amount is shielded end-to-end, so the emitted `Transfer`
        // event must carry the encrypted-bytes overload.
        _shieldedTransfer(msg.sender, recipient, amount, true);
        return true;
    }

    /// @inheritdoc IMYieldToOne
    function approve(address spender, suint256 amount) external returns (bool) {
        _shieldedApprove(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IMYieldToOne
    function transferFrom(address sender, address recipient, suint256 amount) external returns (bool) {
        // User-to-user path via allowance: encrypted-bytes emit.
        _spendAllowanceAndTransfer(sender, recipient, amount, true);
        return true;
    }

    /* ============ Inherited IERC20 / IERC20Extended Entry Points (Allowlist-Gated) ============ */
    // The native `uint256` `approve` / `transferFrom` entry points are re-enabled for trusted M0
    // infra only: `approve` is allowed when the spender is infra, `transferFrom` when the caller is
    // infra (see `_isInfra`). Both write the same `shieldedAllowance` slot as the `suint256` overloads
    // (the `uint256` is only an ABI-boundary cast), so the two paths cannot diverge. Non-infra callers
    // must use the `suint256`-typed overloads above. The native `transfer` and both `permit` overloads
    // stay `pure` reverting — no infra calls them on the extension, so they remain shielded-only.

    /// @inheritdoc IERC20
    function transfer(
        address /* recipient */,
        uint256 /* amount */
    ) external pure override(ERC20ExtendedUpgradeable, IERC20) returns (bool) {
        revert UseShieldedTransfer();
    }

    /// @inheritdoc IERC20
    /// @dev Native `uint256` path, allowed only when `msg.sender` is trusted M0 infra (`_isInfra`).
    ///      Shares the `shieldedAllowance` slot with the `suint256` overload via an ABI-boundary cast;
    ///      everyone else must use `transferFrom(address,address,suint256)`.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override(ERC20ExtendedUpgradeable, IERC20) returns (bool) {
        if (!_isInfra(msg.sender)) revert UseShieldedTransfer();

        // Infra-mediated move: amount is already public on the bridge/calldata side, so
        // the emit stays on the inherited plaintext `Transfer(uint256)` overload.
        _spendAllowanceAndTransfer(sender, recipient, suint256(amount), false);
        return true;
    }

    /// @inheritdoc IERC20
    /// @dev Native `uint256` path, allowed only when `spender` is trusted M0 infra (`_isInfra`).
    ///      Writes the same `shieldedAllowance` slot as `approve(address,suint256)` via an
    ///      ABI-boundary cast; everyone else must use `approve(address,suint256)`.
    function approve(
        address spender,
        uint256 amount
    ) external override(ERC20ExtendedUpgradeable, IERC20) returns (bool) {
        if (!_isInfra(spender)) revert UseShieldedApprove();

        _shieldedApprove(msg.sender, spender, suint256(amount));
        return true;
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
    ///      TxSeismic type 0x4A — plain `eth_call` zeroes `msg.sender` and reverts), or any
    ///      trusted M0 infra address (`_isInfra`: the `swapFacility` immutable plus the
    ///      admin-curated allowlist). The infra exemption lets shared M0 infrastructure
    ///      (e.g. LimitOrderProtocol, which reads user balances to deliver liquidity) observe
    ///      extension balances for operational paths it controls; the holder's balance is not
    ///      exposed to arbitrary callers.
    function balanceOf(address account) public view override returns (uint256) {
        if (msg.sender != account && !_isInfra(msg.sender)) revert Unauthorized();
        return uint256(_getMYieldToOneStorageLocation().balanceOf[account]);
    }

    /// @inheritdoc IERC20
    function totalSupply() public view returns (uint256) {
        return _getMYieldToOneStorageLocation().totalSupply;
    }

    /// @inheritdoc IERC20
    /// @dev Shielded read. Requires `msg.sender == owner` or `msg.sender == spender`; external
    ///      clients must use a Seismic signed read (TxSeismic type 0x4A). The inherited
    ///      unshielded `ERC20ExtendedStorageStruct.allowance` slot is no longer written to (native
    ///      `approve` writes the `shieldedAllowance` slot instead, and `permit` reverts), so this
    ///      gated view is the sole readable allowance source.
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

    /// @inheritdoc IMYieldToOne
    function isAllowlisted(address account) external view returns (bool) {
        return _getMYieldToOneStorageLocation().allowlist[account];
    }

    /// @inheritdoc IMYieldToOne
    function publicKeyOf(address account) external view returns (bytes memory) {
        return _getMYieldToOneStorageLocation().publicKeys[account];
    }

    /// @inheritdoc IMYieldToOne
    function contractPublicKey() external view returns (bytes memory) {
        return _getMYieldToOneStorageLocation()._contractPublicKey;
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
     * @dev   Shared allowance-spend + transfer path for both the shielded `transferFrom(suint256)`
     *        and the native, infra-gated `transferFrom(uint256)` overloads. Reads and decrements the
     *        shielded allowance in shielded space, then delegates to `_shieldedTransfer`. The single
     *        `shieldedAllowance` slot is the only allowance store, so both overloads stay consistent.
     * @dev   Reverts with `InsufficientAllowance(spender, 0, amount)` — zeroing the allowance field so
     *        the revert payload does not leak the shielded allowance value (native path included).
     * @param encryptEmit If `true`, the downstream `_shieldedTransfer` emits the encrypted-bytes
     *                    `Transfer(address,address,bytes)` overload; otherwise it emits the inherited
     *                    plaintext `Transfer(address,address,uint256)` overload. The flag never
     *                    changes the allowance or balance logic, only the event shape.
     */
    function _spendAllowanceAndTransfer(address sender, address recipient, suint256 amount, bool encryptEmit) internal {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();
        suint256 spenderAllowance = $.shieldedAllowance[sender][msg.sender];

        // Infinite-allowance shortcut mirrors `ERC20ExtendedUpgradeable.transferFrom` (line 106):
        // a max-value allowance does not decrement. The cast to `uint256` is a control-flow
        // comparison only — it does not write back to storage and does not leak the shielded
        // value to any external observer.
        if (uint256(spenderAllowance) != type(uint256).max) {
            if (spenderAllowance < amount) revert IERC20Extended.InsufficientAllowance(msg.sender, 0, uint256(amount));

            // NOTE: Can be `unchecked` because the `spenderAllowance < amount` check above guarantees
            //       `spenderAllowance >= amount`, so the subtraction never underflows.
            unchecked {
                $.shieldedAllowance[sender][msg.sender] = spenderAllowance - amount;
            }
        }

        _shieldedTransfer(sender, recipient, amount, encryptEmit);
    }

    /**
     * @dev   Shielded transfer pipeline. Mirrors the structure of `MExtension._transfer` but
     *        entry-points to the same `_update` primitive via a `suint256 → uint256` bridge.
     *        Reuses the existing `_beforeTransfer` hook for freeze/pause checks.
     * @dev   Reverts with `InsufficientBalance(account, 0, amount)` — zeroing the `balance`
     *        field so the revert payload does not leak the shielded balance value, matching
     *        the precedent set by `_revertIfInsufficientBalance`.
     * @param encryptEmit Selects the `Transfer` event overload: `true` emits the
     *                    encrypted-bytes overload via `_emitEncryptedTransfer` (user-to-user
     *                    `suint256` entry points); `false` emits the inherited plaintext
     *                    `Transfer(uint256)` overload (native infra-gated `transferFrom`,
     *                    where the amount is already public via the bridge calldata).
     */
    function _shieldedTransfer(address sender, address recipient, suint256 amount, bool encryptEmit) internal {
        uint256 amount_ = uint256(amount);

        _revertIfInvalidRecipient(recipient);
        _beforeTransfer(sender, recipient, amount_);

        if (encryptEmit) {
            _emitEncryptedTransfer(sender, recipient, amount);
        } else {
            emit Transfer(sender, recipient, amount_);
        }

        if (amount_ == 0) return;

        if (_getMYieldToOneStorageLocation().balanceOf[sender] < amount) {
            revert InsufficientBalance(sender, 0, amount_);
        }

        _update(sender, recipient, amount_);
    }

    /* ============ Encrypted Transfer Event Pipeline ============ */

    /**
     * @dev   Emits the encrypted-bytes `Transfer(address,address,bytes)` overload for a
     *        user-to-user shielded transfer. The amount is encrypted under an AES-GCM key
     *        derived from ECDH between the contract's private key and the recipient's
     *        registered public key, plus HKDF.
     * @dev   Unregistered-recipient fallback: if the recipient has not called
     *        `registerPublicKey`, the event is emitted with empty `bytes` and the transfer
     *        still succeeds. The recipient recovers the amount only via their own gated
     *        `balanceOf` read — historical amounts are not recoverable from logs.
     *        See `docs/seismic-question-encrypted-events-ux.md`.
     * @dev   Reverts `ContractKeyNotSet` if the admin has not yet installed the contract
     *        keypair via `setContractKey`. This is a configuration error, not a runtime
     *        failure — it should only ever fire on a misconfigured deployment.
     * @dev   The AES-GCM nonce is derived from a contract-wide monotonic counter
     *        (`encryptedEventNonce`) hashed with `(from, to)` — see slot 8 NatSpec for
     *        the rationale (departure from the tutorial's collision-prone formulation).
     * @param from   The sender of the transfer (mirrors `Transfer.from`).
     * @param to     The recipient of the transfer (mirrors `Transfer.to`).
     * @param amount The shielded amount being transferred.
     */
    function _emitEncryptedTransfer(address from, address to, suint256 amount) internal {
        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();
        bytes memory pubKey = $.publicKeys[to];

        // Unregistered recipient — emit the empty-ciphertext fallback (transfer still
        // succeeds; amount recoverable only via gated `balanceOf`).
        if (pubKey.length == 0) {
            emit Transfer(from, to, bytes(""));
            return;
        }

        // The control-flow comparison only — see `setContractKey` NatSpec for the open
        // question filed with Seismic about shielded-storage zero-sentinel reads.
        if (bytes32($.contractPrivateKey) == bytes32(0)) revert ContractKeyNotSet();

        // Pre-increment so the first emitted nonce uses counter value 1, and no two
        // encrypted emits ever share a nonce under the same AES-GCM key.
        uint256 n = ++$.encryptedEventNonce;

        sbytes32 sharedSecret = _ecdh($.contractPrivateKey, pubKey);
        sbytes32 aesKey = _hkdf(sharedSecret);
        bytes12 nonce = bytes12(keccak256(abi.encode(from, to, n)));
        bytes memory ciphertext = _aesGcmEncrypt(aesKey, nonce, abi.encode(uint256(amount)));

        emit Transfer(from, to, ciphertext);
    }

    /**
     * @dev   Thin wrapper around the Seismic ECDH precompile at `0x65`. Computes the
     *        shared secret between `privKey` (kept in shielded storage) and the
     *        recipient's compressed (33-byte) `peerPubKey`. The output is shielded so it
     *        stays in flagged storage for the HKDF step.
     * @dev   Reverts `PrecompileFailed(0x65)` if the precompile returns failure.
     * @dev   Open question filed with Seismic (see `docs/seismic-question-encrypted-events-ux.md`):
     *        confirm the canonical precompile addresses and the `abi.encodePacked` input
     *        layout against the production Seismic precompile contract.
     */
    function _ecdh(sbytes32 privKey, bytes memory peerPubKey) internal view returns (sbytes32) {
        (bool success, bytes memory result) = address(0x65).staticcall(abi.encodePacked(bytes32(privKey), peerPubKey));
        if (!success) revert PrecompileFailed(address(0x65));
        return sbytes32(abi.decode(result, (bytes32)));
    }

    /**
     * @dev   Thin wrapper around the Seismic HKDF precompile at `0x68`. Expands the ECDH
     *        shared secret into a fresh AES-GCM key. Both input and output are shielded.
     * @dev   Reverts `PrecompileFailed(0x68)` if the precompile returns failure.
     * @dev   Open question filed with Seismic: confirm the precompile address and input
     *        layout. See `docs/seismic-question-encrypted-events-ux.md`.
     */
    function _hkdf(sbytes32 sharedSecret) internal view returns (sbytes32) {
        (bool success, bytes memory result) = address(0x68).staticcall(abi.encodePacked(bytes32(sharedSecret)));
        if (!success) revert PrecompileFailed(address(0x68));
        return sbytes32(abi.decode(result, (bytes32)));
    }

    /**
     * @dev   Thin wrapper around the Seismic AES-GCM-encrypt precompile at `0x66`.
     *        Encrypts `plaintext` under `key` with the supplied 12-byte `nonce` and
     *        returns the raw ciphertext (authentication tag included, per the
     *        precompile's wire format).
     * @dev   Reverts `PrecompileFailed(0x66)` if the precompile returns failure.
     * @dev   Open question filed with Seismic: confirm the precompile address, input
     *        layout, and whether the returned ciphertext already includes the GCM tag
     *        or whether the caller is expected to append it. See
     *        `docs/seismic-question-encrypted-events-ux.md`.
     */
    function _aesGcmEncrypt(sbytes32 key, bytes12 nonce, bytes memory plaintext) internal view returns (bytes memory) {
        (bool success, bytes memory ciphertext) = address(0x66).staticcall(
            abi.encodePacked(bytes32(key), nonce, plaintext)
        );
        if (!success) revert PrecompileFailed(address(0x66));
        return ciphertext;
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
     * @dev    Returns whether `account` is trusted M0 infra — the single place the `swapFacility`
     *         immutable and the dynamic allowlist are OR'd together. `swapFacility` is permanently
     *         exempt (immutable, cannot be admin-removed); every other infra address (Portal,
     *         LimitOrderProtocol, ...) is curated in the admin-gated allowlist.
     *         Gates the native `approve` / `transferFrom` paths and the `balanceOf` read.
     * @param  account The address being checked.
     * @return Whether the address is trusted M0 infra.
     */
    function _isInfra(address account) internal view returns (bool) {
        return account == swapFacility || _getMYieldToOneStorageLocation().allowlist[account];
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

    /**
     * @dev   Sets the infra allowlist status of `account`.
     * @param account The address whose allowlist status is being set.
     * @param status  The new allowlist status (`true` = allowlisted).
     */
    function _setAllowlisted(address account, bool status) internal {
        if (account == address(0)) revert ZeroAllowlistAccount();

        MYieldToOneStorageStruct storage $ = _getMYieldToOneStorageLocation();

        // Return early if the status is unchanged.
        if ($.allowlist[account] == status) return;

        $.allowlist[account] = status;

        emit AllowlistSet(account, status);
    }
}
