// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

/**
 * @title  Swap Facility interface.
 * @author M0 Labs
 */
interface ISwapFacility {
    /* ============ Events ============ */

    event Swapped(address indexed extensionIn, address indexed extensionOut, uint256 amount, address recipient);

    event SwappedM(address indexed extensionOut, uint256 amount, address recipient);

    /* ============ Custom Errors ============ */

    /// @notice Thrown in the constructor if $M Token is 0x0.
    error ZeroMToken();

    /// @notice Thrown in the constructor if Registrar is 0x0.
    error ZeroRegistrar();

    /// @notice Thrown in `swap` and `swapM` functions if the swap amount is zero.
    error ZeroAmount();

    /// @notice Thrown in `swap` and `swapM` functions if the recipient is 0x0.
    error ZeroRecipient();

    /// @notice Thrown in `swap` and `swapM` functions if the extension is not TTG approved earner.
    error NotApprovedExtension(address extension);

    /* ============ Interactive Functions ============ */

    /**
     * @notice Swaps $M token to $M Extension.
     * @param extensionOut The address of the M Extension to swap to.
     * @param amount       The amount of $M token to swap.
     * @param recipient    The address to receive the swapped $M Extension tokens.
     */
    function swapM(address extensionOut, uint256 amount, address recipient) external;

    /**
     * @notice Swaps one $M Extension to another.
     * @param extensionIn  The address of the $M Extension to swap from.
     * @param extensionOut The address of the $M Extension to swap to.
     * @param amount       The amount to swap.
     * @param recipient    The address to receive the swapped $M Extension tokens.
     */
    function swap(address extensionIn, address extensionOut, uint256 amount, address recipient) external;

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
}
