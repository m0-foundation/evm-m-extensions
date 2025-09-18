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
    bytes32 public constant COLLATERAL_MANAGER_ROLE = keccak256("COLLATERAL_MANAGER_ROLE");

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
        address collateralManager,
        address secondaryBacker
    ) public virtual initializer {
        __MDualBackedYieldToOne_init(
            name,
            symbol,
            yieldRecipient,
            admin,
            freezeManager,
            yieldRecipientManager,
            collateralManager,
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
        address collateralManager,
        address secondaryBacker
    ) internal onlyInitializing {
        if (collateralManager == address(0)) revert ZeroCollateralManager();
        if (secondaryBacker == address(0)) revert ZeroSecondaryBacker();

        __MYieldToOne_init(name, symbol, yieldRecipient, admin, freezeManager, yieldRecipientManager);

        _grantRole(COLLATERAL_MANAGER_ROLE, collateralManager);

        MDualBackedYieldToOneStorageStruct storage $ = _getMDualBackedYieldToOneStorageLocation();

        $.secondaryBacker = secondaryBacker;
    }

    function secondaryBacker() public view returns (address) {
        return _getMDualBackedYieldToOneStorageLocation().secondaryBacker;
    }

    function secondarySupply() public view returns (uint256) {
        return _getMDualBackedYieldToOneStorageLocation().secondarySupply;
    }

    function yield() public view override(IMYieldToOne, MYieldToOne) returns (uint256) {
        unchecked {
            uint256 mBalance_ = _mBalanceOf(address(this));
            uint256 mBacking_ = totalSupply() - secondarySupply();

            return mBalance_ > mBacking_ ? mBalance_ - mBacking_ : 0;
        }
    }

    function replaceSecondary(uint256 amount) external onlyRole(COLLATERAL_MANAGER_ROLE) {
        IMTokenLike(mToken).transferFrom(msg.sender, address(this), amount);

        MDualBackedYieldToOneStorageStruct storage $ = _getMDualBackedYieldToOneStorageLocation();

        unchecked {
            $.secondarySupply -= amount;
        }

        IERC20($.secondaryBacker).transfer(msg.sender, amount);

        emit SecondaryBackingReplaced(amount);
    }

    function wrapSecondary(address recipient, uint256 amount) external onlySwapFacility {
        // NOTE: `msg.sender` is always SwapFacility contract.
        //       `ISwapFacility.msgSender()` is used to ensure that the original caller is passed to `_beforeWrap`.
        _wrapSecondary(ISwapFacility(msg.sender).msgSender(), recipient, amount);
    }

    function _wrapSecondary(address account, address recipient, uint256 amount) internal {
        _revertIfInvalidRecipient(recipient);
        _revertIfInsufficientAmount(amount);

        // NOTE: Invoke the _beforeUnwrap() hook from yield to one
        _beforeWrap(account, recipient, amount);

        // NOTE: `msg.sender` is always SwapFacility contract.
        // NOTE: The behavior of `IMTokenLike.transferFrom` is known, so its return can be ignored.
        MDualBackedYieldToOneStorageStruct storage $ = _getMDualBackedYieldToOneStorageLocation();

        IERC20($.secondaryBacker).transferFrom(msg.sender, address(this), amount);

        unchecked {
            $.secondarySupply += amount;
        }

        _mint(recipient, amount);
    }

    function _beforeUnwrap(address account, uint256 amount) internal view virtual override {
        uint256 mBacking = totalSupply() - secondarySupply();

        if (amount > mBacking) revert InsufficientMBacking();
    }
}
