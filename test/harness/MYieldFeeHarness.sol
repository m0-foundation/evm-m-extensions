// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldFee } from "../../src/projects/yieldToAllWithFee/MYieldFee.sol";

contract MYieldFeeHarness is MYieldFee {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MYieldFee(mToken, swapFacility) {}

    function initialize(
        string memory name,
        string memory symbol,
        uint16 feeRate,
        address feeRecipient,
        address admin,
        address feeManager,
        address claimRecipientManager,
        address freezeManager,
        address pauser
    ) public override initializer {
        super.initialize(
            name,
            symbol,
            feeRate,
            feeRecipient,
            admin,
            feeManager,
            claimRecipientManager,
            freezeManager,
            pauser
        );
    }

    function latestEarnerRateAccrualTimestamp() external view returns (uint40) {
        return _latestEarnerRateAccrualTimestamp();
    }

    function currentEarnerRate() external view returns (uint32) {
        return _currentEarnerRate();
    }

    function setAccountOf(address account, uint256 balance, uint112 principal) external {
        MYieldFeeStorageStruct storage $ = _getMYieldFeeStorageLocation();

        $.balanceOf[account] = balance;
        $.principalOf[account] = principal;
    }

    function setIsEarningEnabled(bool isEarningEnabled_) external {
        _getMYieldFeeStorageLocation().isEarningEnabled = isEarningEnabled_;
    }

    function setLatestIndex(uint256 latestIndex_) external {
        _getMYieldFeeStorageLocation().latestIndex = uint128(latestIndex_);
    }

    function setLatestRate(uint256 latestRate_) external {
        _getMYieldFeeStorageLocation().latestRate = uint32(latestRate_);
    }

    function setLatestUpdateTimestamp(uint256 latestUpdateTimestamp_) external {
        _getMYieldFeeStorageLocation().latestUpdateTimestamp = uint40(latestUpdateTimestamp_);
    }

    function setTotalSupply(uint256 totalSupply_) external {
        _getMYieldFeeStorageLocation().totalSupply = totalSupply_;
    }

    function setTotalPrincipal(uint112 totalPrincipal_) external {
        _getMYieldFeeStorageLocation().totalPrincipal = totalPrincipal_;
    }
}
