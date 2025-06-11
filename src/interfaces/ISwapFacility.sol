// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

interface ISwapFacility {
    /* ============ Events ============ */

    event Swapped(address indexed extensionIn, address indexed extensionOut, uint256 amount, address recipient);

    event SwappedM(address indexed extensionOut, uint256 amount, address recipient);

    event ApprovedMTokenSwapperSet(address indexed swapper, bool approved);

    /* ============ Custom Errors ============ */

    /// @notice Emitted in the constructor if M Token is 0x0.
    error ZeroMToken();

    /// @notice Emitted in the constructor if Registrar is 0x0.
    error ZeroRegistrar();

    error ZeroAmount();

    error ZeroRecipient();

    error NotApprovedExtension(address extension);

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
}
