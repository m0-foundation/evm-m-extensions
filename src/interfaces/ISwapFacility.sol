// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

interface ISwapFacility {
    /* ============ Events ============ */

    event Swapped(address indexed extensionIn, address indexed extensionOut, uint256 amount, address recipient);

    event SwappedM(address indexed extensionOut, uint256 amount, address recipient);

    event ApprovedMTokenSwapperSet(address indexed swapper, bool approved);

    /* ============ Custom Errors ============ */

    /// @notice Thrown in the constructor if M Token is 0x0.
    error ZeroMToken();

    /// @notice Thrown in the constructor if Registrar is 0x0.
    error ZeroRegistrar();

    /// @notice Thrown in `swap` and `swapM` functions if the swap amount is zero.
    error ZeroAmount();

    /// @notice Thrown in `swap` and `swapM` functions if the recipient is 0x0.
    error ZeroRecipient();

    /// @notice Thrown in `swap` and `swapM` functions if the extension is not TTG approved earner.
    error NotApprovedExtension(address extension);

    /// @notice Thrown in `swapM` function if the swapper is not an approved M Token swapper.
    error NotApprovedSwapper(address swapper);

    /* ============ Interactive Functions ============ */

    function swapM(address extensionOut, uint256 amount, address recipient) external;

    function swap(address extensionIn, address extensionOut, uint256 amount, address recipient) external;

    function setApprovedMTokenSwapper(address swapper, bool approved) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The address of the M Token contract.
    function mToken() external view returns (address mToken);

    /// @notice The address of the Registrar.
    function registrar() external view returns (address registrar);

    /**
     * @notice Returns the address that called `swap` or `swapM`
     * @dev    Must be used instead of `msg.sender` in M Extensions contracts to get the original sender.
     */
    function msgSender() external view returns (address msgSender);
}
