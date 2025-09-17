// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import {
    AccessControlUpgradeable
} from "../../../lib/common/lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";

import { IMDualBackedToOne } from "./IMDualBackedToOne.sol";

import { ISwapFacility } from "../../swap/interfaces/ISwapFacility.sol";

import { MExtension } from "../../MExtension.sol";

import { IMTokenLike } from "../../interfaces/IMTokenLike.sol";

abstract contract MDualBackedToOneStorageLayout {
    struct MDualBackedToOneStorageStruct {
        address yieldRecipient;
        IERC20 secondaryBacker;
        uint256 secondarySupply;
        uint256 totalSupply;
        mapping(address account => uint256 balance) balanceOf;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.MDualBackedToOne")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _M_DUAL_BACKED_TO_ONE_STORAGE_LOCATION =
        0xee2f6fc7e2e5879b17985791e0d12536cba689bda43c77b8911497248f4af100;

    function _getMDualBackedToOneStorageLocation() internal pure returns (MDualBackedToOneStorageStruct storage $) {
        assembly {
            $.slot := _M_DUAL_BACKED_TO_ONE_STORAGE_LOCATION
        }
    }
}

/**
 * @title  MDualBacked
 * @notice Upgradeable ERC20 Token contract for wrapping M alongside a secondary token
 *         into a non rebasing asset with a single yield recipient
 * @author M0 Labs
 */

contract MDualBackedToOne is IMDualBackedToOne, MDualBackedToOneStorageLayout, AccessControlUpgradeable, MExtension {
    /// @inheritdoc IMDualBackedToOne
    bytes32 public constant COLLATERAL_MANAGER_ROLE = keccak256("COLLATERAL_MANAGER_ROLE");

    /// @inheritdoc IMDualBackedToOne
    bytes32 public constant YIELD_RECIPIENT_MANAGER_ROLE = keccak256("YIELD_RECIPIENT_MANAGER_ROLE");

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs MDualBacking Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken       The address of $M token.
     * @param  swapFacility The address of Swap Facility.
     */
    constructor(address mToken, address swapFacility) MExtension(mToken, swapFacility) {
        _disableInitializers();
    }

    /* ============ Initializer ============ */

    /**
     * @dev   Initializes the M extension token with yield claimable by a single recipient.
     * @param name                  The name of the token (e.g. "M Yield to One").
     * @param symbol                The symbol of the token (e.g. "MYO").
     * @param secondaryBacker       The address of the secondary collateral (e.g. USDC)
     * @param admin                 The address of an admin.
     * @param collateralManager     The address of the initial collateral manager.
     * @param yieldRecipientManager The address of the initial yield recipient manager.
     * @param yieldRecipient        The address of the initial yield recipient.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address secondaryBacker,
        address admin,
        address collateralManager,
        address yieldRecipientManager,
        address yieldRecipient
    ) public virtual initializer {
        __MDualBacked_init(
            name,
            symbol,
            secondaryBacker,
            admin,
            collateralManager,
            yieldRecipientManager,
            yieldRecipient
        );
    }

    /**
     * @notice Initializes the MYieldToOne token.
     * @param name                  The name of the token (e.g. "M Yield to One").
     * @param symbol                The symbol of the token (e.g. "MYO").
     * @param secondaryBacker       The address of the secondary collateral (e.g. USDC)
     * @param admin                 The address of an admin.
     * @param collateralManager     The address of the initial collateral manager.
     * @param yieldRecipientManager The address of the initial yield recipient manager.
     * @param yieldRecipient        The address of the initial yield recipient.
     */
    function __MDualBacked_init(
        string memory name,
        string memory symbol,
        address secondaryBacker,
        address admin,
        address collateralManager,
        address yieldRecipientManager,
        address yieldRecipient
    ) internal onlyInitializing {
        if (yieldRecipientManager == address(0)) revert ZeroYieldRecipientManager();
        if (admin == address(0)) revert ZeroAdmin();

        __MExtension_init(name, symbol);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(COLLATERAL_MANAGER_ROLE, collateralManager);
        _grantRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager);

        _setYieldRecipient(yieldRecipient);

        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();
        $.secondaryBacker = IERC20(secondaryBacker);
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view override returns (uint256) {
        return _getMDualBackedToOneStorageLocation().balanceOf[account];
    }

    /// @inheritdoc IERC20
    function totalSupply() public view override returns (uint256) {
        return _getMDualBackedToOneStorageLocation().totalSupply;
    }

    /// @inheritdoc IMDualBackedToOne
    function secondaryBacker() public view returns (IERC20) {
        return _getMDualBackedToOneStorageLocation().secondaryBacker;
    }

    /// @inheritdoc IMDualBackedToOne
    function secondarySupply() public view returns (uint256) {
        return _getMDualBackedToOneStorageLocation().secondarySupply;
    }

    /// @inheritdoc IMDualBackedToOne
    function yield() public view returns (uint256) {
        unchecked {
            uint256 balance_ = _mBalanceOf(address(this));
            uint256 mBacking_ = totalSupply() - secondarySupply();

            return balance_ > mBacking_ ? balance_ - mBacking_ : 0;
        }
    }

    /// @inheritdoc IMDualBackedToOne
    function claimYield() public returns (uint256) {
        _beforeClaimYield();

        uint256 yield_ = yield();

        if (yield_ == 0) return 0;

        emit YieldClaimed(yield_);

        _mint(yieldRecipient(), yield_);

        return yield_;
    }

    function setYieldRecipient(address account) external onlyRole(YIELD_RECIPIENT_MANAGER_ROLE) {
        claimYield();

        _setYieldRecipient(account);
    }

    function yieldRecipient() public view returns (address) {
        return _getMDualBackedToOneStorageLocation().yieldRecipient;
    }

    function wrapSecondary(address recipient, uint256 amount) external onlySwapFacility {
        // NOTE: `msg.sender` is always SwapFacility contract.
        //       `ISwapFacility.msgSender()` is used to ensure that the original caller is passed to `_beforeWrap`.
        _wrapSecondary(ISwapFacility(msg.sender).msgSender(), recipient, amount);
    }

    function replaceSecondary(uint256 amount) external onlyRole(COLLATERAL_MANAGER_ROLE) {
        IMTokenLike(mToken).transferFrom(msg.sender, address(this), amount);

        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();

        $.secondaryBacker.transfer(msg.sender, _scaleDecimals(amount));

        $.secondarySupply -= amount;

        emit SecondaryBackingReplaced(amount);
    }

    function _wrapSecondary(address account, address recipient, uint256 amount) internal {
        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        // NOTE: Invoke the _beforeUnwrap() hook from yield to one
        _beforeWrap(account, recipient, amount);

        // NOTE: `msg.sender` is always SwapFacility contract.
        // NOTE: The behavior of `IMTokenLike.transferFrom` is known, so its return can be ignored.
        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();
        $.secondaryBacker.transferFrom(msg.sender, address(this), _scaleDecimals(amount));

        unchecked {
            $.secondarySupply += amount;
        }

        _mint(recipient, amount);
    }

    function _scaleDecimals(uint256 amount) internal view {
        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();
        return amount * (10 ** $.secondaryBacker.decimals());
    }

    function _beforeApprove(address account, address spender, uint256 amount) internal virtual override {}

    function _beforeWrap(address account, address recipient, uint256 amount) internal virtual override {}

    function _beforeUnwrap(address account, uint256 amount) internal view virtual override {
        uint256 secondarySupply = secondarySupply();
        uint256 mBacking = totalSupply() - secondarySupply;

        if (amount > mBacking) revert InsufficientMBacking();
    }

    function _beforeTransfer(address sender, address recipient, uint256 /* amount */) internal view virtual override {}

    function _beforeClaimYield() internal view virtual {}

    function _mint(address account, uint256 amount) internal override {
        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();

        unchecked {
            $.balanceOf[account] += amount;
            $.totalSupply += amount;
        }

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();

        unchecked {
            $.balanceOf[account] -= amount;
            $.totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _update(address sender, address recipient, uint256 amount) internal override {
        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();

        unchecked {
            $.balanceOf[sender] -= amount;
            $.balanceOf[recipient] += amount;
        }
    }

    /**
     * @dev Sets the yield recipient.
     * @param yieldRecipient_ The address of the new yield recipient.
     */
    function _setYieldRecipient(address yieldRecipient_) internal {
        if (yieldRecipient_ == address(0)) revert ZeroYieldRecipient();

        MDualBackedToOneStorageStruct storage $ = _getMDualBackedToOneStorageLocation();

        if (yieldRecipient_ == $.yieldRecipient) return;

        $.yieldRecipient = yieldRecipient_;

        emit YieldRecipientSet(yieldRecipient_);
    }
}
