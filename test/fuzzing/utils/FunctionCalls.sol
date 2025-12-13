// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@perimetersec/fuzzlib/src/FuzzBase.sol";
import "../helpers/FuzzStorageVariables.sol";
import { IERC20 } from "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";
import { MEarnerManager } from "src/projects/earnerManager/MEarnerManager.sol";
import { MYieldFee } from "src/projects/yieldToAllWithFee/MYieldFee.sol";
import { SwapFacility } from "src/swap/SwapFacility.sol";
import { MExtension } from "src/MExtension.sol";
import { MToken } from "test/fuzzing/mocks/MToken.sol";
import { IUniswapV3SwapAdapter } from "src/swap/UniswapV3SwapAdapter.sol";
import { IMExtension } from "src/interfaces/IMExtension.sol";
import { JMIExtension } from "src/projects/jmi/JMIExtension.sol";
import { Pausable } from "src/components/pausable/Pausable.sol";
import { Freezable } from "src/components/freezable/Freezable.sol";

contract FunctionCalls is FuzzBase, FuzzStorageVariables {
    // MToken function calls
    event StartEarningCall();
    event StopEarningCall();

    // MYieldToOne function calls
    event ClaimYieldCall(address instance);
    event SetYieldRecipientCall(address instance, address yieldRecipient);
    event EnableEarningCall(address instance);
    event DisableEarningCall(address instance);
    event ApproveCall(address instance, address spender, uint256 amount);
    event TransferCall(address instance, address to, uint256 amount);
    event TransferFromCall(address instance, address from, address to, uint256 amount);
    event WrapCall(address instance, address recipient, uint256 amount);
    event UnwrapCall(address instance, address recipient, uint256 amount);

    // Madmin function calls
    event SetAccountInfoCall(address instance, address account, bool status, uint16 feeRate);
    event SetAccountInfoBatchCall(address instance, address[] accounts, bool[] statuses, uint16[] feeRates);
    event SetFeeRecipientCall(address instance, address feeRecipient);
    event ClaimForCall(address instance, address account);

    // MYieldFee function calls
    event ClaimYieldForCall(address instance, address account);
    event ClaimFeeCall(address instance);
    event UpdateIndexCall(address instance);
    event SetFeeRateCall(address instance, uint16 feeRate);
    event SetClaimRecipientCall(address instance, address account, address claimRecipient);

    // SwapFacility function calls
    event SwapCall(address instance, address extensionIn, address extensionOut, uint256 amount, address recipient);
    event SwapInMCall(address instance, address extensionOut, uint256 amount, address recipient);
    event SwapOutMCall(address instance, address extensionIn, uint256 amount, address recipient);
    event SwapInMWithPermitVRSCall(
        address instance,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    event SwapInMWithPermitSignatureCall(
        address instance,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes signature
    );
    event SwapInTokenCall(
        address instance,
        address tokenIn,
        uint256 amountIn,
        address extensionOut,
        uint256 minAmountOut,
        address recipient,
        bytes path
    );
    event SwapOutTokenCall(
        address instance,
        address extensionIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        address recipient,
        bytes path
    );

    // MToken function calls
    event MintCall(address account, uint256 amount);

    // JMI Extension function calls
    event WrapAssetCall(address instance, address asset, address recipient, uint256 amount);
    event ReplaceAssetWithMCall(address instance, address asset, address recipient, uint256 amount);
    event SetAssetCapCall(address instance, address asset, uint256 cap);

    // Pausable function calls
    event PauseCall(address instance);
    event UnpauseCall(address instance);

    // Freezable function calls
    event FreezeCall(address instance, address account);
    event UnfreezeCall(address instance, address account);

    // MYieldToOne function implementations
    function _claimYieldCall(address instance) internal returns (bool success, bytes memory returnData) {
        emit ClaimYieldCall(instance);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(MYieldToOne.claimYield.selector));
    }

    function _setYieldRecipientCall(
        address instance,
        address yieldRecipient
    ) internal returns (bool success, bytes memory returnData) {
        emit SetYieldRecipientCall(instance, yieldRecipient);
        vm.prank(yieldRecipientManager);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(MYieldToOne.setYieldRecipient.selector, yieldRecipient)
        );
    }

    function _approveCall(
        address instance,
        address spender,
        uint256 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit ApproveCall(instance, spender, amount);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, amount)
        );
    }

    function _transferCall(
        address instance,
        address to,
        uint256 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit TransferCall(instance, to, amount);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
    }

    function _transferFromCall(
        address instance,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit TransferFromCall(instance, from, to, amount);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );
    }

    function _wrapCall(
        address instance,
        address recipient,
        uint256 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit WrapCall(instance, recipient, amount);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(MExtension.wrap.selector, recipient, amount)
        );
    }

    function _unwrapCall(
        address instance,
        address recipient,
        uint256 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit UnwrapCall(instance, recipient, amount);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(MExtension.unwrap.selector, recipient, amount)
        );
    }

    // Madmin function implementations
    function _setAccountInfoCall(
        address instance,
        address account,
        bool status,
        uint16 feeRate
    ) internal returns (bool success, bytes memory returnData) {
        emit SetAccountInfoCall(instance, account, status, feeRate);
        vm.prank(admin);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(bytes4(keccak256("setAccountInfo(address,bool,uint16)")), account, status, feeRate)
        );
    }

    function _setFeeRecipientCall(
        address instance,
        address feeRecipient
    ) internal returns (bool success, bytes memory returnData) {
        emit SetFeeRecipientCall(instance, feeRecipient);
        vm.prank(admin);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(MEarnerManager.setFeeRecipient.selector, feeRecipient)
        );
    }

    function _setFeeRecipientCall_MYieldFee(
        address instance,
        address feeRecipient
    ) internal returns (bool success, bytes memory returnData) {
        emit SetFeeRecipientCall(instance, feeRecipient);
        vm.prank(admin);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(MEarnerManager.setFeeRecipient.selector, feeRecipient)
        );
    }

    function _claimForCall(address instance, address account) internal returns (bool success, bytes memory returnData) {
        emit ClaimForCall(instance, account);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(bytes4(keccak256("claimFor(address)")), account)
        );
    }

    // MYieldFee function implementations
    function _claimYieldForCall(
        address instance,
        address account
    ) internal returns (bool success, bytes memory returnData) {
        emit ClaimYieldForCall(instance, account);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(MYieldFee.claimYieldFor.selector, account)
        );
    }

    function _claimFeeCall(address instance) internal returns (bool success, bytes memory returnData) {
        emit ClaimFeeCall(instance);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(MYieldFee.claimFee.selector));
    }

    function _updateIndexCall(address instance) internal returns (bool success, bytes memory returnData) {
        emit UpdateIndexCall(instance);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(MYieldFee.updateIndex.selector));
    }

    function _setFeeRateCall(
        address instance,
        uint16 feeRate
    ) internal returns (bool success, bytes memory returnData) {
        emit SetFeeRateCall(instance, feeRate);
        vm.prank(admin);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(MYieldFee.setFeeRate.selector, feeRate));
    }

    function _setClaimRecipientCall(
        address instance,
        address account,
        address claimRecipient
    ) internal returns (bool success, bytes memory returnData) {
        emit SetClaimRecipientCall(instance, account, claimRecipient);
        vm.prank(admin);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(MYieldFee.setClaimRecipient.selector, account, claimRecipient)
        );
    }

    // SwapFacility function implementations
    function _swapCall(
        address instance,
        address extensionIn,
        address extensionOut,
        uint256 amount,
        address recipient
    ) internal returns (bool success, bytes memory returnData) {
        emit SwapCall(instance, extensionIn, extensionOut, amount, recipient);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(SwapFacility.swap.selector, extensionIn, extensionOut, amount, recipient)
        );
    }

    function _swapInMCall(
        address instance,
        address extensionOut,
        uint256 amount,
        address recipient
    ) internal returns (bool success, bytes memory returnData) {
        emit SwapInMCall(instance, extensionOut, amount, recipient);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(SwapFacility.swapInM.selector, extensionOut, amount, recipient)
        );
    }

    function _swapOutMCall(
        address instance,
        address extensionIn,
        uint256 amount,
        address recipient
    ) internal returns (bool success, bytes memory returnData) {
        emit SwapOutMCall(instance, extensionIn, amount, recipient);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(SwapFacility.swapOutM.selector, extensionIn, amount, recipient)
        );
    }

    function _swapInMWithPermitVRSCall(
        address instance,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bool success, bytes memory returnData) {
        emit SwapInMWithPermitVRSCall(instance, extensionOut, amount, recipient, deadline, v, r, s);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(
                bytes4(keccak256("swapInMWithPermit(address,uint256,address,uint256,uint8,bytes32,bytes32)")),
                extensionOut,
                amount,
                recipient,
                deadline,
                v,
                r,
                s
            )
        );
    }

    function _swapInMWithPermitSignatureCall(
        address instance,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes memory signature
    ) internal returns (bool success, bytes memory returnData) {
        emit SwapInMWithPermitSignatureCall(instance, extensionOut, amount, recipient, deadline, signature);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(
                bytes4(keccak256("swapInMWithPermit(address,uint256,address,uint256,bytes)")),
                extensionOut,
                amount,
                recipient,
                deadline,
                signature
            )
        );
    }

    function _swapInTokenCall(
        address instance,
        address tokenIn,
        uint256 amountIn,
        address extensionOut,
        uint256 minAmountOut,
        address recipient,
        bytes memory path
    ) internal returns (bool success, bytes memory returnData) {
        emit SwapInTokenCall(instance, tokenIn, amountIn, extensionOut, minAmountOut, recipient, path);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(
                IUniswapV3SwapAdapter.swapIn.selector,
                tokenIn,
                amountIn,
                extensionOut,
                minAmountOut,
                recipient,
                path
            )
        );
    }

    function _swapOutTokenCall(
        address instance,
        address extensionIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        address recipient,
        bytes memory path
    ) internal returns (bool success, bytes memory returnData) {
        emit SwapOutTokenCall(instance, extensionIn, amountIn, tokenOut, minAmountOut, recipient, path);
        vm.prank(currentActor);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(
                IUniswapV3SwapAdapter.swapOut.selector,
                extensionIn,
                amountIn,
                tokenOut,
                minAmountOut,
                recipient,
                path
            )
        );
    }

    function _mintCall(address account, uint256 amount) internal returns (bool success, bytes memory returnData) {
        emit MintCall(account, amount);
        vm.prank(address(this));
        (success, returnData) = address(mToken).call(abi.encodeWithSelector(MToken.mint.selector, account, amount));
    }

    function _startEarningCall(address account) internal returns (bool success, bytes memory returnData) {
        emit StartEarningCall();
        vm.prank(currentActor);
        (success, returnData) = address(mToken).call(abi.encodeWithSelector(MToken.startEarning.selector, account));
    }

    function _stopEarningCall(address account) internal returns (bool success, bytes memory returnData) {
        emit StopEarningCall();
        vm.prank(currentActor);
        (success, returnData) = address(mToken).call(
            abi.encodeWithSelector(bytes4(keccak256("stopEarning(address)")), account)
        );
    }

    function _enableEarningCall(address instance) internal returns (bool success, bytes memory returnData) {
        emit EnableEarningCall(instance);
        // vm.prank(currentActor);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(IMExtension.enableEarning.selector));
    }

    function _disableEarningCall(address instance) internal returns (bool success, bytes memory returnData) {
        emit DisableEarningCall(instance);
        // vm.prank(currentActor);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(IMExtension.disableEarning.selector));
    }

    // JMI Extension function implementations
    function _wrapAssetCall(
        address instance,
        address asset,
        address recipient,
        uint256 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit WrapAssetCall(instance, asset, recipient, amount);
        vm.prank(address(swapFacility));
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(JMIExtension.wrap.selector, asset, recipient, amount)
        );
    }

    function _replaceAssetWithMCall(
        address instance,
        address asset,
        address recipient,
        uint256 amount
    ) internal returns (bool success, bytes memory returnData) {
        emit ReplaceAssetWithMCall(instance, asset, recipient, amount);
        vm.prank(address(swapFacility));
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(JMIExtension.replaceAssetWithM.selector, asset, recipient, amount)
        );
    }

    function _setAssetCapCall(
        address instance,
        address asset,
        uint256 cap
    ) internal returns (bool success, bytes memory returnData) {
        emit SetAssetCapCall(instance, asset, cap);
        vm.prank(assetCapManager);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(JMIExtension.setAssetCap.selector, asset, cap)
        );
    }

    // Pausable function implementations
    function _pauseCall(address instance) internal returns (bool success, bytes memory returnData) {
        emit PauseCall(instance);
        vm.prank(pauser);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(Pausable.pause.selector));
    }

    function _unpauseCall(address instance) internal returns (bool success, bytes memory returnData) {
        emit UnpauseCall(instance);
        vm.prank(pauser);
        (success, returnData) = address(instance).call(abi.encodeWithSelector(Pausable.unpause.selector));
    }

    // Freezable function implementations
    function _freezeCall(
        address instance,
        address account
    ) internal returns (bool success, bytes memory returnData) {
        emit FreezeCall(instance, account);
        vm.prank(freezeManager);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(Freezable.freeze.selector, account)
        );
    }

    function _unfreezeCall(
        address instance,
        address account
    ) internal returns (bool success, bytes memory returnData) {
        emit UnfreezeCall(instance, account);
        vm.prank(freezeManager);
        (success, returnData) = address(instance).call(
            abi.encodeWithSelector(Freezable.unfreeze.selector, account)
        );
    }
}
