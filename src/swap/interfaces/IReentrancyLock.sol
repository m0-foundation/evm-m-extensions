// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

/**
 * @title  Reentrancy Lock for SwapFacility contract.
 * @author M0 Labs
 */
interface IReentrancyLock {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a router is added to or removed from the list of trusted routers.
     * @param router  The address of the router.
     * @param trusted True if the router is trusted, false otherwise.
     */
    event TrustedRouterSet(address indexed router, bool trusted);

    /* ============ Custom Errors ============ */

    /// @notice Thrown if contract is already locked.
    error ContractLocked();

    /// @notice Thrown if the admin is 0x0.
    error ZeroAdmin();

    /// @notice Thrown if the router is 0x0.
    error ZeroRouter();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Sets the trusted status of a router.
     * @param router The address of the router.
     * @param trusted The trusted status to set - `true` to add, `false` to remove router from the trusted list.
     */
    function setTrustedRouter(address router, bool trusted) external;

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns whether a router is trusted or not.
     * @param router The address of the router.
     * @return trusted True if the router is trusted, false otherwise.
     */
    function isTrustedRouter(address router) external view returns (bool trusted);
}
