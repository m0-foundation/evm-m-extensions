// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
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

    /// @notice Fee for Uniswap V3 swap router (0.01%)
    uint24 internal constant UNISWAP_V3_FEE = 100;

    /// @notice Path address size
    uint256 internal constant PATH_ADDR_SIZE = 20;

    /// @notice Path fee size
    uint256 internal constant PATH_FEE_SIZE = 3;

    /// @notice Path next offset
    uint256 internal constant PATH_NEXT_OFFSET = PATH_ADDR_SIZE + PATH_FEE_SIZE;

    /// @inheritdoc IUniswapV3SwapAdapter
    address public immutable wrappedMToken;

    /// @inheritdoc IUniswapV3SwapAdapter
    address public immutable swapFacility;

    /// @inheritdoc IUniswapV3SwapAdapter
    address public immutable swapRouter;

    mapping(address token => bool whitelisted) public whitelistedTokens;

    /**
     * @notice Constructs UniswapV3SwapAdapter contract
     * @param  wrappedMToken_ The address of base token.
     * @param  swapRouter_    The address of the Uniswap V3 swap router.
     * @param  admin          The address of the admin.
     * @param  tokens         The list of whitelisted tokens.
     */
    constructor(
        address wrappedMToken_,
        address swapFacility_,
        address swapRouter_,
        address admin,
        address[] memory tokens
    ) {
        if ((wrappedMToken = wrappedMToken_) == address(0)) revert ZeroWrappedMToken();
        if ((swapFacility = swapFacility_) == address(0)) revert ZeroSwapFacility();
        if ((swapRouter = swapRouter_) == address(0)) revert ZeroSwapRouter();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        for (uint256 i; i < tokens.length; i++) {
            _whitelistToken(tokens[i], true);
        }
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
        IERC20(tokenIn).forceApprove(swapRouter, amountIn);

        // Swap tokenIn to Wrapped $M in Uniswap V3 pool
        uint256 amountOut = IV3SwapRouter(swapRouter).exactInput(
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
            IERC20(wrappedMToken).approve(address(swapFacility), amountOut);
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

        uint256 extensionInBalanceBefore = IERC20(extensionIn).balanceOf(address(this));

        IERC20(extensionIn).transferFrom(msg.sender, address(this), amountIn);

        // Swap the extensionIn to Wrapped $M token
        if (extensionIn != wrappedMToken) {
            IERC20(extensionIn).approve(address(swapFacility), amountIn);
            ISwapFacility(swapFacility).swap(extensionIn, wrappedMToken, amountIn, address(this));
        }

        IERC20(wrappedMToken).approve(swapRouter, amountIn);

        // Swap Wrapped $M to tokenOut in Uniswap V3 pool
        uint256 amountOut = IV3SwapRouter(swapRouter).exactInput(
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
        uint256 remainingBalance = IERC20(extensionIn).balanceOf(address(this)) - extensionInBalanceBefore;
        if (remainingBalance > 0) {
            IERC20(extensionIn).transfer(msg.sender, remainingBalance);
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
        whitelistedTokens[token] = isWhitelisted;

        emit TokenWhitelisted(token, isWhitelisted);
    }

    /**
     * @notice Decode input and output tokens
     * @param  path Swap path
     * @return tokenInput Address of the input token
     * @return tokenOutput Address if the output token
     */
    function _decodeInputAndOutputTokens(
        bytes calldata path
    ) internal pure returns (address tokenInput, address tokenOutput) {
        // Validate path format
        if (
            (path.length < PATH_ADDR_SIZE + PATH_FEE_SIZE + PATH_ADDR_SIZE) ||
            ((path.length - PATH_ADDR_SIZE) % PATH_NEXT_OFFSET != 0)
        ) {
            revert InvalidPathFormat();
        }

        tokenInput = address(bytes20(path[:PATH_ADDR_SIZE]));

        // Calculate position of output token
        uint256 numHops = (path.length - PATH_ADDR_SIZE) / PATH_NEXT_OFFSET;
        uint256 outputTokenIndex = numHops * PATH_NEXT_OFFSET;

        tokenOutput = address(bytes20(path[outputTokenIndex:outputTokenIndex + PATH_ADDR_SIZE]));
    }

    /**
     * @dev   Reverts if not whitelisted token.
     * @param token Address of a token.
     */
    function _revertIfNotWhitelistedToken(address token) internal view {
        if (token != wrappedMToken && !whitelistedTokens[token]) revert NotWhitelistedToken(token);
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
     * @param  tokenInput Address of the input token.
     * @param  path Swap path.
     */
    function _revertIfInvalidSwapInPath(address tokenInput, bytes calldata path) internal view {
        if (path.length != 0) {
            (address tokenInput_, address tokenOutput) = _decodeInputAndOutputTokens(path);
            if (tokenInput_ != tokenInput || tokenOutput != wrappedMToken) revert InvalidPath();
        }
    }

    /**
     * @notice Reverts if the swap path is invalid for swapping out.
     * @param  tokenOutput Address of the output token.
     * @param  path Swap path.
     */
    function _revertIfInvalidSwapOutPath(address tokenOutput, bytes calldata path) internal view {
        if (path.length != 0) {
            (address tokenInput, address tokenOutput_) = _decodeInputAndOutputTokens(path);
            if (tokenInput != wrappedMToken || tokenOutput_ != tokenOutput) revert InvalidPath();
        }
    }
}
