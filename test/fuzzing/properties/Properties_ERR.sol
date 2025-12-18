//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./RevertHandler.sol";
import "../../../src/projects/yieldToAllWithFee/interfaces/IMSpokeYieldFee.sol";
import "../../../src/projects/yieldToAllWithFee/interfaces/IMYieldFee.sol";
import "../../../src/projects/yieldToOne/interfaces/IMYieldToOne.sol";
import "../../../src/projects/earnerManager/IMEarnerManager.sol";
import {
    IERC712,
    IERC3009,
    IWrappedMToken,
    IMigratable,
    UIntMath,
    IStatefulERC712,
    IERC20Extended
} from "test/fuzzing/mocks/WrappedMToken.f.sol";
import { IUniswapV3SwapAdapter } from "src/swap/interfaces/IUniswapV3SwapAdapter.sol";
import { IMExtension } from "src/interfaces/IMExtension.sol";
import { IAccessControl } from "lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import { V3SwapRouter } from "uniswapv3/v3-periphery/V3SwapRouter.sol";

abstract contract Properties_ERR is RevertHandler {
    /*
     *
     * FUZZ NOTE: CHECK REVERTS CONFIGURATION IN FUZZ STORAGE VARIABLES
     *
     */

    function _getAllowedPanicCodes() internal pure virtual override returns (uint256[] memory) {
        uint256[] memory panicCodes = new uint256[](3);
        panicCodes[0] = PANIC_ENUM_OUT_OF_BOUNDS;
        panicCodes[1] = PANIC_POP_EMPTY_ARRAY;
        panicCodes[2] = PANIC_ARRAY_OUT_OF_BOUNDS;

        // Add additional codes
        return panicCodes;
    }

    // Add additional errors here
    // Example:
    // Deposit errors [0-5]
    // allowedErrors[0] = IUsdnProtocolErrors.UsdnProtocolEmptyVault.selector;
    // allowedErrors[1] = IUsdnProtocolErrors
    //     .UsdnProtocolDepositTooSmall
    //     .selector;

    function _getAllowedCustomErrors() internal pure virtual override returns (bytes4[] memory) {
        bytes4[] memory allowedErrors = new bytes4[](79);

        // IMSpokeYieldFee errors
        allowedErrors[0] = IMSpokeYieldFee.ZeroRateOracle.selector;

        // IMYieldFee errors
        allowedErrors[1] = IMYieldFee.FeeRateTooHigh.selector;
        allowedErrors[2] = IMYieldFee.ZeroAdmin.selector;
        allowedErrors[3] = IMYieldFee.ZeroFeeManager.selector;
        allowedErrors[4] = IMYieldFee.ZeroClaimRecipientManager.selector;
        allowedErrors[5] = IMYieldFee.ZeroFeeRecipient.selector;
        allowedErrors[6] = IMYieldFee.ZeroClaimRecipient.selector;
        allowedErrors[7] = IMYieldFee.ZeroAccount.selector;

        // IMYieldToOne errors
        // allowedErrors[8] = IMYieldToOne.NoYield.selector;
        allowedErrors[9] = IMYieldToOne.ZeroYieldRecipient.selector;
        allowedErrors[10] = IMYieldToOne.ZeroYieldRecipientManager.selector;
        allowedErrors[11] = IMYieldToOne.ZeroAdmin.selector;

        // IMEarnerManager errors
        allowedErrors[12] = IMEarnerManager.ZeroFeeRecipient.selector;
        allowedErrors[13] = IMEarnerManager.ZeroEarnerManager.selector;
        allowedErrors[14] = IMEarnerManager.ZeroAdmin.selector;
        allowedErrors[15] = IMEarnerManager.ZeroAccount.selector;
        allowedErrors[16] = IMEarnerManager.InvalidFeeRate.selector;
        allowedErrors[17] = IMEarnerManager.InvalidAccountInfo.selector;
        allowedErrors[18] = IMEarnerManager.NotWhitelisted.selector;
        allowedErrors[19] = IMEarnerManager.ArrayLengthMismatch.selector;
        allowedErrors[20] = IMEarnerManager.ArrayLengthZero.selector;

        // WrappedMToken errors - IERC712
        allowedErrors[21] = IERC712.InvalidSignature.selector;
        allowedErrors[22] = IERC712.InvalidSignatureLength.selector;
        allowedErrors[23] = IERC712.InvalidSignatureS.selector;
        allowedErrors[24] = IERC712.InvalidSignatureV.selector;
        allowedErrors[25] = IERC712.SignatureExpired.selector;
        allowedErrors[26] = IERC712.SignerMismatch.selector;

        // WrappedMToken errors - IMigratable
        allowedErrors[27] = IMigratable.InvalidMigrator.selector;
        allowedErrors[28] = IMigratable.MigrationFailed.selector;
        allowedErrors[29] = IMigratable.ZeroMigrator.selector;

        // WrappedMToken errors - UIntMath
        allowedErrors[30] = UIntMath.InvalidUInt16.selector;
        allowedErrors[31] = UIntMath.InvalidUInt40.selector;
        allowedErrors[32] = UIntMath.InvalidUInt48.selector;
        allowedErrors[33] = UIntMath.InvalidUInt112.selector;
        allowedErrors[34] = UIntMath.InvalidUInt128.selector;
        allowedErrors[35] = UIntMath.InvalidUInt240.selector;

        // WrappedMToken errors - IndexingMath
        allowedErrors[36] = IndexingMath.DivisionByZero.selector;

        // WrappedMToken errors - IStatefulERC712
        allowedErrors[37] = IStatefulERC712.InvalidAccountNonce.selector;

        // WrappedMToken errors - IERC3009
        allowedErrors[38] = IERC3009.AuthorizationAlreadyUsed.selector;
        allowedErrors[39] = IERC3009.AuthorizationExpired.selector;
        allowedErrors[40] = IERC3009.AuthorizationNotYetValid.selector;
        allowedErrors[41] = IERC3009.CallerMustBePayee.selector;

        // WrappedMToken errors - IERC20Extended
        allowedErrors[42] = IERC20Extended.InsufficientAllowance.selector;
        allowedErrors[43] = IERC20Extended.InsufficientAmount.selector;
        allowedErrors[44] = IERC20Extended.InvalidRecipient.selector;

        // WrappedMToken errors - IWrappedMToken
        allowedErrors[45] = IWrappedMToken.EarningIsDisabled.selector;
        allowedErrors[46] = IWrappedMToken.EarningIsEnabled.selector;
        allowedErrors[47] = IWrappedMToken.EarningCannotBeReenabled.selector;
        allowedErrors[48] = IWrappedMToken.IsApprovedEarner.selector;
        allowedErrors[49] = IWrappedMToken.InsufficientBalance.selector;
        allowedErrors[50] = IWrappedMToken.NotApprovedEarner.selector;
        allowedErrors[51] = IWrappedMToken.UnauthorizedMigration.selector;
        allowedErrors[52] = IWrappedMToken.ZeroMToken.selector;
        allowedErrors[53] = IWrappedMToken.ZeroMigrationAdmin.selector;

        allowedErrors[54] = IAccessControl.AccessControlUnauthorizedAccount.selector;
        allowedErrors[55] = IAccessControl.AccessControlBadConfirmation.selector;

        allowedErrors[56] = IUniswapV3SwapAdapter.ZeroToken.selector;
        allowedErrors[57] = IUniswapV3SwapAdapter.ZeroAmount.selector;
        allowedErrors[58] = IUniswapV3SwapAdapter.ZeroRecipient.selector;
        allowedErrors[59] = IUniswapV3SwapAdapter.NotWhitelistedToken.selector;
        allowedErrors[60] = IUniswapV3SwapAdapter.InvalidPath.selector;
        allowedErrors[61] = IUniswapV3SwapAdapter.InvalidPathFormat.selector;

        allowedErrors[62] = IMExtension.ZeroMToken.selector;
        allowedErrors[63] = IMExtension.ZeroSwapFacility.selector;
        allowedErrors[64] = IMExtension.NotSwapFacility.selector;
        allowedErrors[65] = IMExtension.InsufficientBalance.selector;

        allowedErrors[66] = V3SwapRouter.V3InvalidSwap.selector;

        return allowedErrors;
    }

    function _isAllowedERC20Error(bytes memory returnData) internal pure virtual override returns (bool) {
        bytes[] memory allowedErrors = new bytes[](9);
        allowedErrors[0] = INSUFFICIENT_ALLOWANCE;
        allowedErrors[1] = TRANSFER_FROM_ZERO;
        allowedErrors[2] = TRANSFER_TO_ZERO;
        allowedErrors[3] = APPROVE_TO_ZERO;
        allowedErrors[4] = MINT_TO_ZERO;
        allowedErrors[5] = BURN_FROM_ZERO;
        allowedErrors[6] = DECREASED_ALLOWANCE;
        allowedErrors[7] = BURN_EXCEEDS_BALANCE;
        allowedErrors[8] = EXCEEDS_BALANCE_ERROR;

        for (uint256 i = 0; i < allowedErrors.length; i++) {
            if (keccak256(returnData) == keccak256(allowedErrors[i])) {
                return true;
            }
        }

        // Check UniswapV3 string errors
        return _isAllowedUniswapV3Error(returnData);
    }

    function _isAllowedUniswapV3Error(bytes memory returnData) internal pure returns (bool) {
        bytes[] memory allowedErrors = new bytes[](51);

        // Short error codes
        allowedErrors[0] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "LOK");
        allowedErrors[1] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "TLU");
        allowedErrors[2] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "TLM");
        allowedErrors[3] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "TUM");
        allowedErrors[4] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "AI");
        allowedErrors[5] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "M0");
        allowedErrors[6] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "M1");
        allowedErrors[7] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "AS");
        allowedErrors[8] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "SPL");
        allowedErrors[9] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "IIA");
        allowedErrors[10] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "L");
        allowedErrors[11] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "F0");
        allowedErrors[12] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "F1");
        allowedErrors[13] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "NEO");
        allowedErrors[14] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ONI");
        allowedErrors[15] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "TD");
        allowedErrors[16] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "STE");
        allowedErrors[17] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "LS");
        allowedErrors[18] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "LA");
        allowedErrors[19] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "NP");
        allowedErrors[20] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "I");
        allowedErrors[21] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "LO");
        allowedErrors[22] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "T");
        allowedErrors[23] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "R");
        allowedErrors[24] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "BP");
        allowedErrors[25] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "NI");
        allowedErrors[26] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "DL");

        // Long error messages
        allowedErrors[27] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Transaction too old");
        allowedErrors[28] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Too little received");
        allowedErrors[29] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Too much requested");
        allowedErrors[30] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Permit expired");
        allowedErrors[31] = abi.encodeWithSelector(
            bytes4(keccak256("Error(string)")),
            "ERC721Permit: approval to current owner"
        );
        allowedErrors[32] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Invalid signature");
        allowedErrors[33] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Unauthorized");
        allowedErrors[34] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Not WETH9");
        allowedErrors[35] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Insufficient WETH9");
        allowedErrors[36] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Insufficient token");
        allowedErrors[37] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Price slippage check");
        allowedErrors[38] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Blockhash");
        allowedErrors[39] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Invalid token ID");
        allowedErrors[40] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "Not cleared");
        allowedErrors[41] = abi.encodeWithSelector(
            bytes4(keccak256("Error(string)")),
            "ERC721: approved query for nonexistent token"
        );
        allowedErrors[42] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "slice_overflow");
        allowedErrors[43] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "slice_outOfBounds");
        allowedErrors[44] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "toAddress_overflow");
        allowedErrors[45] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "toAddress_outOfBounds");
        allowedErrors[46] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "toUint24_overflow");
        allowedErrors[47] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "toUint24_outOfBounds");
        allowedErrors[48] = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "invalid base64 decoder input");
        allowedErrors[49] = abi.encodeWithSelector(
            bytes4(keccak256("Error(string)")),
            "Strings: hex length insufficient"
        );
        allowedErrors[50] = abi.encodeWithSelector(
            bytes4(keccak256("Error(string)")),
            "AddressStringUtil: INVALID_LEN"
        );

        for (uint256 i = 0; i < allowedErrors.length; i++) {
            if (keccak256(returnData) == keccak256(allowedErrors[i])) {
                return true;
            }
        }
        return false;
    }

    function _getAllowedSoladyERC20Error() internal pure virtual override returns (bytes4[] memory) {
        bytes4[] memory allowedErrors = new bytes4[](0);
        // allowedErrors[0] = SafeTransferLib.ETHTransferFailed.selector;
        // allowedErrors[1] = SafeTransferLib.TransferFromFailed.selector;
        // allowedErrors[2] = SafeTransferLib.TransferFailed.selector;
        // allowedErrors[3] = SafeTransferLib.ApproveFailed.selector;
        // allowedErrors[4] = SafeTransferLib.Permit2Failed.selector;
        // allowedErrors[5] = SafeTransferLib.Permit2AmountOverflow.selector;
        // allowedErrors[6] = bytes4(0x82b42900); //unauthorized selector

        return allowedErrors;
    }
}
