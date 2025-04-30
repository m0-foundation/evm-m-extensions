// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.26;

/**
 * @title  Rate Oracle Interface.
 * @author M0 Labs
 */
interface IRateOracle {
    /**
     * @notice Returns the current value of earner rate in basis points.
     *         This value does not account for the compounding interest.
     */
    function earnerRate() external view returns (uint32);
}
