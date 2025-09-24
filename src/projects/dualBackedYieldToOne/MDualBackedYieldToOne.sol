// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { IERC20 } from "../../../lib/common/src/interfaces/IERC20.sol";

import { MYieldToOne } from "../yieldToOne/MYieldToOne.sol";

import { IMYieldToOne } from "../yieldToOne/IMYieldToOne.sol";

import { IMDualBackedYieldToOne } from "./IMDualBackedYieldToOne.sol";

import { ISwapFacility } from "../../swap/interfaces/ISwapFacility.sol";

import { IMTokenLike } from "../../interfaces/IMTokenLike.sol";

abstract contract MDualBackedToYieldOneStorageLayout {
    struct MDualBackedYieldToOneStorageStruct {
        address secondaryBacker;
        uint256 secondarySupply;
        uint256 secondaryDecimals;
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

/// @custom:oz-upgrades-unsafe-allow missing-initializer
/// @custom:oz-upgrades-unsafe-allow constructor

contract MDualBackedYieldToOne is IMDualBackedYieldToOne, MDualBackedToYieldOneStorageLayout, MYieldToOne {
    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs MYieldToOne Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken       The address of $M token.
     * @param  swapFacility The address of Swap Facility.
     */
    constructor(address mToken, address swapFacility) MYieldToOne(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address secondaryBacker
    ) public virtual initializer {
        __MDualBackedYieldToOne_init(
            name,
            symbol,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            secondaryBacker
        );
    }

    function __MDualBackedYieldToOne_init(
        string memory name,
        string memory symbol,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address secondaryBacker
    ) internal onlyInitializing {
        if (secondaryBacker == address(0)) revert ZeroSecondaryBacker();

        __MYieldToOne_init(name, symbol, yieldRecipient, admin, freezeManager, yieldRecipientManager);

        _setSecondaryBacker(secondaryBacker);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMYieldToOne
    function yield() public view override(IMYieldToOne, MYieldToOne) returns (uint256) {
        unchecked {
            uint256 mBalance_ = _mBalanceOf(address(this));
            uint256 mBacking_ = _mBacking();

            return mBalance_ > mBacking_ ? mBalance_ - mBacking_ : 0;
        }
    }

    /// @inheritdoc IMDualBackedYieldToOne
    function replaceSecondary(address recipient, uint256 amount) external onlySwapFacility {
        _replaceSecondary(recipient, amount);
    }

    /// @inheritdoc IMDualBackedYieldToOne
    function wrapSecondary(address recipient, uint256 amount) external onlySwapFacility {
        // NOTE: `msg.sender` is always SwapFacility contract.
        //       `ISwapFacility.msgSender()` is used to ensure that the original caller is passed to `_beforeWrap`.
        _wrapSecondary(ISwapFacility(msg.sender).msgSender(), recipient, amount);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IMDualBackedYieldToOne
    function secondaryBacker() public view returns (address) {
        return _getMDualBackedYieldToOneStorageLocation().secondaryBacker;
    }

    /// @inheritdoc IMDualBackedYieldToOne
    function secondarySupply() public view returns (uint256) {
        return _getMDualBackedYieldToOneStorageLocation().secondarySupply;
    }

    /* ============ Hooks For Internal Interactive Functions ============ */

    function _beforeUnwrap(address account, uint256 amount) internal view virtual override {
        super._beforeUnwrap(account, amount);

        uint256 mBacking = _mBacking();
        if (amount > mBacking) revert InsufficientMBacking();
    }

    /* ============ Internal Interactive Functions ============ */

    function _wrapSecondary(address account, address recipient, uint256 amount) internal {
        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        _beforeWrap(account, recipient, amount);

        MDualBackedYieldToOneStorageStruct storage $ = _getMDualBackedYieldToOneStorageLocation();

        IERC20($.secondaryBacker).transferFrom(msg.sender, address(this), amount);

        unchecked {
            $.secondarySupply += amount;
        }

        _mint(recipient, amount);
    }

    function _replaceSecondary(address recipient, uint256 amount) internal {
        IMTokenLike(mToken).transferFrom(msg.sender, address(this), amount);

        MDualBackedYieldToOneStorageStruct storage $ = _getMDualBackedYieldToOneStorageLocation();

        unchecked {
            $.secondarySupply -= amount;
        }

        IERC20($.secondaryBacker).transfer(recipient, amount);

        emit SecondaryBackingReplaced(amount);
    }

    function _setSecondaryBacker(address secondaryBacker) internal {
        MDualBackedYieldToOneStorageStruct storage $ = _getMDualBackedYieldToOneStorageLocation();

        $.secondaryBacker = secondaryBacker;
    }

    /* ============ Internal View Functions ============ */

    function _mBacking() internal view returns (uint256) {
        unchecked {
            return totalSupply() - secondarySupply();
        }
    }
}
