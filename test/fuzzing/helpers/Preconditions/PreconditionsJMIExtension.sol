// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";
import "../Structs/StructsJMIExtension.sol";
import { JMIExtension } from "src/projects/jmi/JMIExtension.sol";

contract PreconditionsJMIExtension is PreconditionsBase {
    // ==============================================================
    // JMIExtension Preconditions
    // ==============================================================

    /**
     * @notice Preconditions for JMIExtension.setAssetCap
     * @dev Clamps asset to valid token addresses and cap to reasonable range
     */
    function jmi_setAssetCapPreconditions(
        uint256 assetSeed,
        uint256 capSeed
    ) internal returns (JMI_SetAssetCapParams memory params) {
        params.instance = address(jmiExtension);

        // Select asset - use DAI or other available tokens
        params.asset = address(DAI);

        // Clamp cap to reasonable range (0 to 10 billion tokens with 18 decimals)
        params.cap = fl.clamp(capSeed, 0, 10_000_000_000e18);
    }

    /**
     * @notice Preconditions for JMIExtension.pause
     */
    function jmi_pausePreconditions(uint256 instanceSeed) internal returns (JMI_PauseParams memory params) {
        params.instance = address(jmiExtension);
    }

    /**
     * @notice Preconditions for JMIExtension.unpause
     */
    function jmi_unpausePreconditions(uint256 instanceSeed) internal returns (JMI_PauseParams memory params) {
        params.instance = address(jmiExtension);
    }

    /**
     * @notice Preconditions for JMIExtension.freeze
     * @dev Selects account from USERS array
     */
    function jmi_freezePreconditions(
        uint256 instanceSeed,
        uint256 accountSeed
    ) internal returns (JMI_FreezeParams memory params) {
        params.instance = address(jmiExtension);
        params.account = USERS[accountSeed % USERS.length];
    }

    /**
     * @notice Preconditions for JMIExtension.unfreeze
     * @dev Selects account from USERS array
     */
    function jmi_unfreezePreconditions(
        uint256 instanceSeed,
        uint256 accountSeed
    ) internal returns (JMI_UnfreezeParams memory params) {
        params.instance = address(jmiExtension);
        params.account = USERS[accountSeed % USERS.length];
    }
}
