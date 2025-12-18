// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "uniswapv3/v3-periphery/base/PeripheryPaymentsWithFee.sol";

// import "uniswapv3/v3-periphery/interfaces/IPeripheryPaymentsWithFeeExtended.sol";
import "uniswapv3/v3-periphery/base/PeripheryPaymentsExtended.sol";

// IPeripheryPaymentsWithFeeExtended,
abstract contract PeripheryPaymentsWithFeeExtended is PeripheryPaymentsExtended, PeripheryPaymentsWithFee {
    function unwrapWETH9WithFee(uint256 amountMinimum, uint256 feeBips, address feeRecipient) external payable {
        unwrapWETH9WithFee(amountMinimum, msg.sender, feeBips, feeRecipient);
    }

    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable {
        sweepTokenWithFee(token, amountMinimum, msg.sender, feeBips, feeRecipient);
    }
}
