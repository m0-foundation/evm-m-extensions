// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "uniswapv3/v3-periphery/base/PeripheryPaymentsWithFee.sol";

// import "uniswapv3/v3-periphery/interfaces/IPeripheryPaymentsWithFeeExtended.sol";
import "uniswapv3/v3-periphery/base/PeripheryPaymentsExtended.sol";

abstract contract PeripheryPaymentsWithFeeExtended is
    IPeripheryPaymentsWithFeeExtended,
    PeripheryPaymentsExtended,
    PeripheryPaymentsWithFee
{
    /// @inheritdoc IPeripheryPaymentsWithFeeExtended
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable override {
        unwrapWETH9WithFee(amountMinimum, msg.sender, feeBips, feeRecipient);
    }

    /// @inheritdoc IPeripheryPaymentsWithFeeExtended
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable override {
        sweepTokenWithFee(token, amountMinimum, msg.sender, feeBips, feeRecipient);
    }
}
