// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./PropertiesBase.sol";
// import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

abstract contract RevertHandler is PropertiesBase {
    function invariant_ERR(bytes memory returnData) internal {
        // Handle empty reverts
        if (returnData.length == 0) {
            if (CATCH_EMPTY_REVERTS) {
                fl.t(false, "Empty revert data not allowed");
            } else {
                fl.t(true, "Revert data is empty, allowed by config");
            }

            return;
        }

        bytes4 returnedError;
        assembly {
            returnedError := mload(add(returnData, 0x20))
        }

        // Handle Panic errors
        if (returnedError == bytes4(keccak256("Panic(uint256)"))) {
            _handlePanic(returnData);
            return;
        }

        // Handle Error(string) errors
        if (returnedError == bytes4(keccak256("Error(string)"))) {
            _handleError(returnData);
            return;
        }

        // Handle custom protocol errors
        _handleCustomError(returnData);
    }

    function _getAllowedPanicCodes() internal pure virtual returns (uint256[] memory) {
        uint256[] memory panicCodes = new uint256[](3);
        panicCodes[0] = PANIC_ENUM_OUT_OF_BOUNDS;
        panicCodes[1] = PANIC_POP_EMPTY_ARRAY;
        panicCodes[2] = PANIC_ARRAY_OUT_OF_BOUNDS;
        return panicCodes;
    }

    function _getAllowedCustomErrors() internal pure virtual returns (bytes4[] memory) {
        bytes4[] memory allowedErrors = new bytes4[](1);
        // Uncomment to allow empty reverts:
        // allowedErrors[0] = bytes4(abi.encode(""));
        return allowedErrors;
    }

    function _handleSoladyError(bytes memory returnData) private {
        bytes4 returnedError;
        assembly {
            returnedError := mload(add(returnData, 0x20))
        }

        fl.errAllow(returnedError, _getAllowedSoladyERC20Error(), ERR_01);
    }

    function _getAllowedSoladyERC20Error() internal pure virtual returns (bytes4[] memory) {
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

    function _isAllowedERC20Error(bytes memory returnData) internal pure virtual returns (bool) {
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
        return false;
    }

    function _isAllowedFoundryERC20Error(bytes memory returnData) internal virtual returns (bool) {
        bytes memory ADDITION_OVERFLOW = abi.encodeWithSelector(
            bytes4(keccak256("Error(string)")),
            "ERC20: addition overflow"
        );

        bytes[] memory allowedErrors = new bytes[](1);
        allowedErrors[0] = ADDITION_OVERFLOW;

        for (uint256 i = 0; i < allowedErrors.length; i++) {
            if (keccak256(returnData) == keccak256(allowedErrors[i])) {
                return true;
            }
        }
        return false;
    }

    function _handlePanic(bytes memory returnData) private {
        uint256 panicCode = _extractPanicCode(returnData);
        uint256[] memory allowedCodes = _getAllowedPanicCodes();
        bool isAllowed = false;

        for (uint256 i = 0; i < allowedCodes.length; i++) {
            if (panicCode == allowedCodes[i]) {
                isAllowed = true;
                break;
            }
        }

        fl.log("Panic code", bytes32(panicCode));
        if (!isAllowed) {
            fl.t(false, "Disallowed Panic code encountered!");
        }
    }

    function _handleError(bytes memory returnData) private {
        string memory revertMsg = _extractRevertMessage(returnData);
        fl.log("Error(string) revert returnData: ", revertMsg);

        if (_isAllowedERC20Error(returnData)) {
            fl.log("ERC20 error encountered", revertMsg);
            return;
        }

        if (_isAllowedFoundryERC20Error(returnData)) {
            fl.log("Foundry MockERC20 error encountered", revertMsg);
            return;
        }

        if (CATCH_REQUIRE_REVERT) {
            fl.t(false, revertMsg);
        }
    }

    function _handleCustomError(bytes memory returnData) private {
        bytes4 returnedError;
        assembly {
            returnedError := mload(add(returnData, 0x20))
        }

        fl.log("Custom protocol error returnData: ", _extractRevertMessage(returnData));
        fl.errAllow(returnedError, _getAllowedCustomErrors(), ERR_01);
    }

    function _extractPanicCode(bytes memory revertData) private returns (uint256) {
        fl.log("REVERT DATA LENGTH", revertData.length);
        if (revertData.length < 36) {
            fl.t(false, "Unexpected revert data length for panic code");
            return 0;
        }

        uint256 panicCode;
        assembly {
            panicCode := mload(add(revertData, 36))
        }
        return panicCode;
    }

    function _extractRevertMessage(bytes memory _returnData) private returns (string memory) {
        // If data is too short or not properly formatted, return a default message
        if (_returnData.length < 4) {
            return "Invalid error data";
        }

        // Try-catch block to handle non-decodeable data
        try this._decodeErrorMessage(_returnData) returns (string memory message) {
            return message;
        } catch {
            return string(abi.encodePacked("Non-decodeable error: 0x", FuzzLibString.toHexString(_returnData)));
        }
    }

    // Helper function to safely decode error messages
    function _decodeErrorMessage(bytes memory _data) external pure returns (string memory) {
        // Skip the error selector (first 4 bytes)
        bytes memory strBytes = new bytes(_data.length - 4);
        for (uint256 i = 4; i < _data.length; i++) {
            strBytes[i - 4] = _data[i];
        }
        return abi.decode(strBytes, (string));
    }
}
