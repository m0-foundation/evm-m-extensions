// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { MYieldFee } from "../../src/MYieldFee.sol";

contract MYieldFeeHarness is MYieldFee {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address mToken,
        uint16 yieldFeeRate,
        address yieldFeeRecipient,
        address admin,
        address yieldFeeManager
    ) public override initializer {
        super.initialize(name, symbol, mToken, yieldFeeRate, yieldFeeRecipient, admin, yieldFeeManager);
    }

    function currentBlockTimestamp() external view returns (uint40) {
        return _currentBlockTimestamp();
    }

    function currentEarnerRate() external view returns (uint32) {
        return _currentEarnerRate();
    }

    function setAccountOf(address account, uint256 balance, uint112 principal) external {
        MYieldFeeExtensionStorageStruct storage $ = _getMYieldFeeExtensionStorageLocation();

        $.balanceOf[account] = balance;
        $.principalOf[account] = principal;
    }

    function setLatestIndex(uint256 latestIndex_) external {
        _getMYieldFeeExtensionStorageLocation().latestIndex = uint128(latestIndex_);
    }

    function setLatestRate(uint256 latestRate_) external {
        _getMYieldFeeExtensionStorageLocation().latestRate = uint32(latestRate_);
    }

    function setLatestUpdateTimestamp(uint256 latestUpdateTimestamp_) external {
        _getMYieldFeeExtensionStorageLocation().latestUpdateTimestamp = uint40(latestUpdateTimestamp_);
    }

    function setTotalSupply(uint256 totalSupply_) external {
        _getMYieldFeeExtensionStorageLocation().totalSupply = totalSupply_;
    }

    function setTotalPrincipal(uint112 totalPrincipal_) external {
        _getMYieldFeeExtensionStorageLocation().totalPrincipal = totalPrincipal_;
    }
}
