// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import {
    IERC20
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {
    SafeERC20
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {
    AccessControl
} from "../../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

import { ReentrancyLock } from "../../lib/uniswap-v4-periphery/src/base/ReentrancyLock.sol";

import { IUniswapV3SwapAdapter } from "./interfaces/IUniswapV3SwapAdapter.sol";
import { ISwapFacility } from "./interfaces/ISwapFacility.sol";
import { IV3SwapRouter } from "./interfaces/uniswap/IV3SwapRouter.sol";

/**
 * @title  Uniswap V3 Swap Adapter
 * @author M0 Labs
 *         MetaStreet Foundation
 *         Adapted from https://github.com/metastreet-labs/metastreet-usdai-contracts/blob/main/src/swapAdapters/UniswapV3SwapAdapter.sol
 */
contract UniswapV3SwapAdapter is IUniswapV3SwapAdapter, AccessControl, ReentrancyLock {
    using SafeERC20 for IERC20;

    /// @notice Fee for Uniswap V3 USDC - Wrapped $M pool.
    uint24 internal constant UNISWAP_V3_FEE = 100;

    /// @notice Path address size
    uint256 internal constant PATH_ADDR_SIZE = 20;

    /// @notice Path fee size
    uint256 internal constant PATH_FEE_SIZE = 3;

    /// @notice Path next offset
    uint256 internal constant PATH_NEXT_OFFSET = PATH_ADDR_SIZE + PATH_FEE_SIZE;

    /// @notice Single pool path size
    uint256 internal constant PATH_SINGLE_POOL_SIZE = PATH_ADDR_SIZE + PATH_FEE_SIZE + PATH_ADDR_SIZE;

    /// @inheritdoc IUniswapV3SwapAdapter
    address public immutable wrappedMToken;

    /// @inheritdoc IUniswapV3SwapAdapter
    address public immutable swapFacility;

    /// @inheritdoc IUniswapV3SwapAdapter
    address public immutable uniswapRouter;

    /// @inheritdoc IUniswapV3SwapAdapter
    mapping(address token => bool whitelisted) public whitelistedToken;

    /**
     * @notice Constructs UniswapV3SwapAdapter contract
     * @param  wrappedMToken_      The address of Wrapped $M token.
     * @param  swapFacility_       The address of SwapFacility.
     * @param  uniswapRouter_      The address of the Uniswap V3 swap router.
     * @param  admin               The address of the admin.
     * @param  whitelistedTokens_  The list of whitelisted tokens.
     */
    constructor(
        address wrappedMToken_,
        address swapFacility_,
        address uniswapRouter_,
        address admin,
        address[] memory whitelistedTokens_
    ) {
        if ((wrappedMToken = wrappedMToken_) == address(0)) revert ZeroWrappedMToken();
        if ((swapFacility = swapFacility_) == address(0)) revert ZeroSwapFacility();
        if ((uniswapRouter = uniswapRouter_) == address(0)) revert ZeroUniswapRouter();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        for (uint256 i; i < whitelistedTokens_.length; ++i) {
            _whitelistToken(whitelistedTokens_[i], true);
        }

        // Max approve SwapFacility and Uniswap Router to spend Wrapped $M to save gas
        IERC20(wrappedMToken).approve(swapFacility, type(uint256).max);
        IERC20(wrappedMToken).approve(uniswapRouter, type(uint256).max);
    }

    /// @inheritdoc IUniswapV3SwapAdapter
    function swapIn(
        address tokenIn,
        uint256 amountIn,
        address extensionOut,
        uint256 minAmountOut,
        address recipient,
        bytes calldata path
    ) external isNotLocked {
        _revertIfNotWhitelistedToken(tokenIn);
        _revertIfZeroAmount(amountIn);
        _revertIfInvalidSwapInPath(tokenIn, path);
        _revertIfZeroRecipient(recipient);

        uint256 tokenInBalanceBefore = IERC20(tokenIn).balanceOf(address(this));

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).forceApprove(uniswapRouter, amountIn);

        // Swap tokenIn to Wrapped $M in Uniswap V3 pool
        uint256 amountOut = IV3SwapRouter(uniswapRouter).exactInput(
            IV3SwapRouter.ExactInputParams({
                // If no path is provided, assume tokenIn - Wrapped $M pool with 0.01% fee
                path: path.length == 0 ? abi.encodePacked(tokenIn, UNISWAP_V3_FEE, wrappedMToken) : path,
                // If extensionOut is Wrapped $M, transfer the output token directly to the recipient
                recipient: extensionOut == wrappedMToken ? recipient : address(this),
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            })
        );

        if (extensionOut != wrappedMToken) {
            // Swap the Wrapped $M to extensionOut
            ISwapFacility(swapFacility).swap(wrappedMToken, extensionOut, amountOut, recipient);
        }

        // NOTE: UniswapV3 router allows exactInput operation to not fully utilize
        //       the given input token amount if the pool does not have sufficient liquidity.
        //       Refund any remaining input token balance to the caller.
        uint256 remainingBalance = IERC20(tokenIn).balanceOf(address(this)) - tokenInBalanceBefore;
        if (remainingBalance > 0) {
            IERC20(tokenIn).safeTransfer(msg.sender, remainingBalance);
        }

        emit SwappedIn(tokenIn, amountIn, extensionOut, amountOut, recipient);
    }

    /// @inheritdoc IUniswapV3SwapAdapter
    function swapOut(
        address extensionIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        address recipient,
        bytes calldata path
    ) external isNotLocked {
        _revertIfNotWhitelistedToken(tokenOut);
        _revertIfZeroAmount(amountIn);
        _revertIfInvalidSwapOutPath(tokenOut, path);
        _revertIfZeroRecipient(recipient);

        uint256 wrappedMBalanceBefore = IERC20(wrappedMToken).balanceOf(address(this));

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amountIn);

        // Swap the extensionIn to Wrapped $M token
        if (extensionIn != wrappedMToken) {
            IERC20(extensionIn).approve(address(swapFacility), amountIn);
            ISwapFacility(swapFacility).swap(extensionIn, wrappedMToken, amountIn, address(this));

            // NOTE: added to support WrappedM V1 extension, should be removed in the future after upgrade to WrappedM V2.
            amountIn = IERC20(wrappedMToken).balanceOf(address(this)) - wrappedMBalanceBefore;
        }

        // Swap Wrapped $M to tokenOut in Uniswap V3 pool
        uint256 amountOut = IV3SwapRouter(uniswapRouter).exactInput(
            IV3SwapRouter.ExactInputParams({
                // If no path is provided, assume tokenOut - Wrapped $M pool with 0.01% fee
                path: path.length == 0 ? abi.encodePacked(wrappedMToken, UNISWAP_V3_FEE, tokenOut) : path,
                recipient: recipient,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            })
        );

        // NOTE: UniswapV3 router allows exactInput operations to not fully utilize
        //       the given input token amount if the pool does not have sufficient liquidity.
        //       Refund any remaining input token balance to the caller.
        uint256 remainingBalance = IERC20(wrappedMToken).balanceOf(address(this)) - wrappedMBalanceBefore;
        if (remainingBalance > 0) {
            IERC20(wrappedMToken).transfer(msg.sender, remainingBalance);
        }

        emit SwappedOut(extensionIn, amountIn, tokenOut, amountOut, recipient);
    }

    /// @inheritdoc IUniswapV3SwapAdapter
    function whitelistToken(address token, bool isWhitelisted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whitelistToken(token, isWhitelisted);
    }

    function msgSender() public view returns (address) {
        return _getLocker();
    }

    function _whitelistToken(address token, bool isWhitelisted) private {
        if (token == address(0)) revert ZeroToken();
        if (whitelistedToken[token] == isWhitelisted) return;

        whitelistedToken[token] = isWhitelisted;

        emit TokenWhitelisted(token, isWhitelisted);
    }

    /**
     * @notice Decodes input and output tokens from the Uniswap V3 path.
     * @param  path            The UniswapV3 swap path.
     * @return decodedTokenIn  The address of the input token from the path.
     * @return decodedTokenOut The address of the output token from the path.
     */
    function _decodeAndValidatePathTokens(
        bytes calldata path
    ) internal pure returns (address decodedTokenIn, address decodedTokenOut) {
        // Validate path format
        if ((path.length < PATH_SINGLE_POOL_SIZE) || ((path.length - PATH_ADDR_SIZE) % PATH_NEXT_OFFSET != 0))
            revert InvalidPathFormat();

        decodedTokenIn = address(bytes20(path[:PATH_ADDR_SIZE]));

        // Calculate position of output token
        uint256 numberOfPools = (path.length - PATH_ADDR_SIZE) / PATH_NEXT_OFFSET;
        uint256 outputTokenIndex = numberOfPools * PATH_NEXT_OFFSET;

        decodedTokenOut = address(bytes20(path[outputTokenIndex:outputTokenIndex + PATH_ADDR_SIZE]));
    }

    /**
     * @dev   Reverts if not whitelisted token.
     * @param token Address of a token.
     */
    function _revertIfNotWhitelistedToken(address token) internal view {
        if (!whitelistedToken[token]) revert NotWhitelistedToken(token);
    }

    /**
     * @dev   Reverts if `recipient` is address(0).
     * @param recipient Address of a recipient.
     */
    function _revertIfZeroRecipient(address recipient) internal pure {
        if (recipient == address(0)) revert ZeroRecipient();
    }

    /**
     * @dev   Reverts if `amount` is equal to 0.
     * @param amount Amount of token.
     */
    function _revertIfZeroAmount(uint256 amount) internal pure {
        if (amount == 0) revert ZeroAmount();
    }

    /**
     * @notice Reverts if the swap path is invalid for swapping in.
     * @param  tokenIn The address of the input token provided in `swapIn` function.
     * @param  path    The Uniswap V3 swap path provided in `swapIn` function.
     */
    function _revertIfInvalidSwapInPath(address tokenIn, bytes calldata path) internal view {
        if (path.length != 0) {
            (address decodedTokenIn, address decodedTokenOut) = _decodeAndValidatePathTokens(path);
            if (decodedTokenIn != tokenIn || decodedTokenOut != wrappedMToken) revert InvalidPath();
        }
    }

    /**
     * @notice Reverts if the swap path is invalid for swapping out.
     * @param  tokenOut The address of the output token provided in `swapOut` function.
     * @param  path     The Uniswap V3 swap path provided in `swapOut` function.
     */
    function _revertIfInvalidSwapOutPath(address tokenOut, bytes calldata path) internal view {
        if (path.length != 0) {
            (address decodedTokenIn, address decodedTokenOut) = _decodeAndValidatePathTokens(path);
            if (decodedTokenIn != wrappedMToken || decodedTokenOut != tokenOut) revert InvalidPath();
        }
    }
}
