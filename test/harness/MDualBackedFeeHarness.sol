// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MDualBackedFee } from "../../src/projects/dualBackedFee/MDualBackedFee.sol";
import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

contract MDualBackedFeeHarness is MDualBackedFee {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MDualBackedFee(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        uint16 feeRate,
        address feeRecipient,
        address admin,
        address feeManager,
        address claimRecipientManager,
        address collateralManager,
        IERC20 secondaryBacker
    ) public override initializer {
        super.initialize(
            name,
            symbol,
            feeRate,
            feeRecipient,
            admin,
            feeManager,
            claimRecipientManager,
            collateralManager,
            secondaryBacker
        );
    }

    function latestEarnerRateAccrualTimestamp() external view returns (uint40) {
        return _latestEarnerRateAccrualTimestamp();
    }

    function currentEarnerRate() external view returns (uint32) {
        return _currentEarnerRate();
    }

    function setAccountOf(address account, uint256 balance, uint112 principal) external {
        MDualBackedFeeStorageStruct storage $ = _getMDualBackedFeeStorageLocation();

        $.balanceOf[account] = balance;
        $.principalOf[account] = principal;
    }

    function setIsEarningEnabled(bool isEarningEnabled_) external {
        _getMDualBackedFeeStorageLocation().isEarningEnabled = isEarningEnabled_;
    }

    function setLatestIndex(uint256 latestIndex_) external {
        _getMDualBackedFeeStorageLocation().latestIndex = uint128(latestIndex_);
    }

    function setLatestRate(uint256 latestRate_) external {
        _getMDualBackedFeeStorageLocation().latestRate = uint32(latestRate_);
    }

    function setLatestUpdateTimestamp(uint256 latestUpdateTimestamp_) external {
        _getMDualBackedFeeStorageLocation().latestUpdateTimestamp = uint40(latestUpdateTimestamp_);
    }

    function setTotalSupply(uint256 totalSupply_) external {
        _getMDualBackedFeeStorageLocation().totalSupply = totalSupply_;
    }

    function setTotalPrincipal(uint112 totalPrincipal_) external {
        _getMDualBackedFeeStorageLocation().totalPrincipal = totalPrincipal_;
    }
}
