// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

/**
 * @title  UniswapV3 swap adapter interface.
 * @author M0 Labs
 *         MetaStreet Foundation
 *         Adapted from https://github.com/metastreet-labs/metastreet-usdai-contracts/blob/main/src/swapAdapters/UniswapV3SwapAdapter.sol
 */
interface IUniswapV3SwapAdapter {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a token is swapped in for $M Extension.
     * @param tokenIn      The address of the input token.
     * @param amountIn     The amount of the input token swapped.
     * @param extensionOut The address of the output $M Extension.
     * @param amountOut    The amount of $M Extension tokens received from the swap.
     * @param recipient    The address to receive $M Extension tokens.
     */
    event SwappedIn(
        address indexed tokenIn,
        uint256 amountIn,
        address indexed extensionOut,
        uint256 amountOut,
        address indexed recipient
    );

    /**
     * @notice Emitted when $M Extension is swapped for a token.
     * @param extensionIn The address of the input $M Extension.
     * @param amountIn    The amount of the input $M Extension swapped.
     * @param tokenOut    The address of the output token.
     * @param amountOut   The amount of the output tokens received from the swap.
     * @param recipient   The address to receive output tokens.
     */
    event SwappedOut(
        address indexed extensionIn,
        uint256 amountIn,
        address indexed tokenOut,
        uint256 amountOut,
        address indexed recipient
    );

    /**
     * @notice Emitted when a token is added or removed from the whitelist.
     * @param token The address of the token.
     * @param isWhitelisted True if the token is whitelisted, false otherwise.
     */
    event TokenWhitelisted(address indexed token, bool isWhitelisted);

    /* ============ Custom Errors ============ */

    /// @notice Thrown in the constructor if Wrapped M Token is 0x0.
    error ZeroWrappedMToken();

    /// @notice Thrown in the constructor if SwapFacility is 0x0.
    error ZeroSwapFacility();

    /// @notice Thrown in the constructor if Uniswap Swap Router is 0x0.
    error ZeroUniswapRouter();

    /// @notice Thrown token address is 0x0.
    error ZeroToken();

    /// @notice Thrown if swap amount is 0.
    error ZeroAmount();

    /// @notice Thrown if recipient address is 0x0.
    error ZeroRecipient();

    /// @notice Thrown if the token is not whitelisted.
    error NotWhitelistedToken(address token);

    /// @notice Invalid path
    error InvalidPath();

    /// @notice Invalid path format
    error InvalidPathFormat();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Swaps an external token (e.g. USDC) to $M Extension token using Uniswap pool.
     * @param  tokenIn      The address of the external token to swap from.
     * @param  amountIn     The amount of external tokens to swap.
     * @param  extensionOut The address of the $M Extension to swap to.
     * @param  minAmountOut The minimum amount of $M Extension tokens to receive.
     * @param  recipient    The address to receive $M Extension tokens.
     * @param  path         The Uniswap path. Could be empty for direct pairs.
     */
    function swapIn(
        address tokenIn,
        uint256 amountIn,
        address extensionOut,
        uint256 minAmountOut,
        address recipient,
        bytes calldata path
    ) external;

    /**
     * @notice Swaps $M Extension token to an external token (e.g. USDC) using Uniswap pool.
     * @param  extensionIn  The address of the $M Extension to swap from.
     * @param  amountIn     The amount of $M Extension tokens to swap.
     * @param  tokenOut     The address of the external token to swap to.
     * @param  minAmountOut The minimum amount of external tokens to receive.
     * @param  recipient    The address to receive external tokens.
     * @param  path         The Uniswap path. Could be empty for direct pairs.
     */
    function swapOut(
        address extensionIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        address recipient,
        bytes calldata path
    ) external;

    /**
     * @notice Adds or removes a token from the whitelist of tokens that can be used in Uniswap path.
     * @param  token         The address of the token.
     * @param  isWhitelisted True to whitelist the token, false otherwise.
     */
    function whitelistToken(address token, bool isWhitelisted) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The address of Wrapped M token.
    function wrappedMToken() external view returns (address wrappedMToken);

    /// @notice The address of SwapFacility.
    function swapFacility() external view returns (address swapFacility);

    /// @notice The address of the Uniswap V3 swap router.
    function uniswapRouter() external view returns (address uniswapRouter);

    /**
     * @notice Indicates whether `token` is whitelisted to be used in Uniswap path.
     * @param  token         The address of the token.
     * @return isWhitelisted True if the token is whitelisted, false otherwise.
     */
    function whitelistedToken(address token) external view returns (bool isWhitelisted);
}
