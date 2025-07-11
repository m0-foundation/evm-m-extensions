// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

/**
 * @title  Swap Facility interface.
 * @author M0 Labs
 */
interface ISwapFacility {
    /* ============ Events ============ */

    /**
     * @notice Emitted when $M Extension is swapped for another $M Extension.
     * @param extensionIn  The address of the input $M Extension.
     * @param extensionOut The address of the output $M Extension.
     * @param amount       The amount swapped.
     * @param recipient    The address to receive the output $M Extension token.
     */
    event Swapped(address indexed extensionIn, address indexed extensionOut, uint256 amount, address recipient);

    /**
     * @notice Emitted when $M token is swapped for $M Extension.
     * @param extensionOut The address of the output $M Extension.
     * @param amount       The amount swapped.
     * @param recipient    The address to receive the output $M Extension token.
     */
    event SwappedInM(address indexed extensionOut, uint256 amount, address recipient);

    /**
     * @notice Emitted when $M Extension is swapped for $M token.
     * @param extensionIn  The address of the input $M Extension.
     * @param amount       The amount swapped.
     * @param recipient    The address to receive the $M token.
     */
    event SwappedOutM(address indexed extensionIn, uint256 amount, address recipient);

    /**
     * @notice Emitted when a router is added to or removed from the list of trusted routers.
     * @param router  The address of the router.
     * @param trusted True if the router is trusted, false otherwise.
     */
    event TrustedRouterSet(address indexed router, bool trusted);

    /* ============ Custom Errors ============ */

    /// @notice Thrown in the constructor if $M Token is 0x0.
    error ZeroMToken();

    /// @notice Thrown in the constructor if Registrar is 0x0.
    error ZeroRegistrar();

    /// @notice Thrown in `swap` and `swapM` functions if the extension is not TTG approved earner.
    error NotApprovedExtension(address extension);

    /// @notice Thrown in `swapOutM` and `swapOutMWithPermit` functions if the caller is not approved swapper.
    error NotApprovedSwapper(address account);

    /// @notice Thrown if the router is 0x0.
    error ZeroRouter();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Swaps one $M Extension to another.
     * @param  extensionIn  The address of the $M Extension to swap from.
     * @param  extensionOut The address of the $M Extension to swap to.
     * @param  amount       The amount to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     */
    function swap(address extensionIn, address extensionOut, uint256 amount, address recipient) external;

    /**
     * @notice Swaps one $M Extension to another using permit.
     * @param  extensionIn  The address of the $M Extension to swap from.
     * @param  extensionOut The address of the $M Extension to swap to.
     * @param  amount       The amount to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     * @param  deadline     The last timestamp where the signature is still valid.
     * @param  v            An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  r            An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  s            An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     */
    function swapWithPermit(
        address extensionIn,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Swaps one $M Extension to another using permit.
     * @param  extensionIn  The address of the $M Extension to swap from.
     * @param  extensionOut The address of the $M Extension to swap to.
     * @param  amount       The amount to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     * @param  deadline     The last timestamp where the signature is still valid.
     * @param  signature    An arbitrary signature (EIP-712).
     */
    function swapWithPermit(
        address extensionIn,
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external;

    /**
     * @notice Swaps $M token to $M Extension.
     * @param  extensionOut The address of the M Extension to swap to.
     * @param  amount       The amount of $M token to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     */
    function swapInM(address extensionOut, uint256 amount, address recipient) external;

    /**
     * @notice Swaps $M token to $M Extension using permit.
     * @param  extensionOut The address of the M Extension to swap to.
     * @param  amount       The amount of $M token to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     * @param  deadline     The last timestamp where the signature is still valid.
     * @param  v            An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  r            An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  s            An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     */
    function swapInMWithPermit(
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Swaps $M token to $M Extension using permit.
     * @param  extensionOut The address of the M Extension to swap to.
     * @param  amount       The amount of $M token to swap.
     * @param  recipient    The address to receive the swapped $M Extension tokens.
     * @param  deadline     The last timestamp where the signature is still valid.
     * @param  signature    An arbitrary signature (EIP-712).
     */
    function swapInMWithPermit(
        address extensionOut,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external;

    /**
     * @notice Swaps $M Extension to $M token.
     * @param  extensionIn The address of the $M Extension to swap from.
     * @param  amount      The amount of $M Extension tokens to swap.
     * @param  recipient   The address to receive $M tokens.
     */
    function swapOutM(address extensionIn, uint256 amount, address recipient) external;

    /**
     * @notice Swaps $M Extension to $M token using permit.
     * @param  extensionIn The address of the $M Extension to swap from.
     * @param  amount      The amount of $M Extension tokens to swap.
     * @param  recipient   The address to receive $M tokens.
     * @param  deadline    The last timestamp where the signature is still valid.
     * @param  v           An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  r           An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  s           An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     */
    function swapOutMWithPermit(
        address extensionIn,
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Swaps $M Extension to $M token using permit.
     * @param  extensionIn The address of the $M Extension to swap from.
     * @param  amount      The amount of $M Extension tokens to swap.
     * @param  recipient   The address to receive $M tokens.
     * @param  deadline    The last timestamp where the signature is still valid.
     * @param  signature   An arbitrary signature (EIP-712).
     */
    function swapOutMWithPermit(
        address extensionIn,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external;

    /**
     * @notice Sets a router as trusted or untrusted.
     * @param  router  The address of the router to set.
     * @param  trusted True if the router is trusted, false otherwise.
     */
    function setTrustedRouter(address router, bool trusted) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The address of the $M Token contract.
    function mToken() external view returns (address mToken);

    /// @notice The address of the Registrar.
    function registrar() external view returns (address registrar);

    /**
     * @notice Returns the address that called `swap` or `swapM`
     * @dev    Must be used instead of `msg.sender` in $M Extensions contracts to get the original sender.
     */
    function msgSender() external view returns (address msgSender);

    /**
     * @notice Returns whether the given router is trusted and implements `IMsgSender`.
     * @param  router  The address of the router.
     * @return trusted True if the router is trusted, false otherwise.
     */
    function trustedRouter(address router) external view returns (bool trusted);
}
