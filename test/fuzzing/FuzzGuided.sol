// SPDX-License-Identifier: UNTITLED
pragma solidity ^0.8.0;

import "./FuzzMYieldToOne.sol";
import "./FuzzMEarnerManager.sol";
import "./FuzzMYieldFee.sol";
import "./FuzzSwapFacility.sol";
import "./FuzzMToken.sol";
import "./FuzzUni.sol";
import "./FuzzJMIExtension.sol";

contract FuzzGuided is FuzzUni, FuzzMYieldToOne, FuzzMEarnerManager, FuzzMYieldFee, FuzzSwapFacility, FuzzMToken, FuzzJMIExtension {
// , FuzzMYieldToOne, FuzzMEarnerManager, FuzzMYieldFee, FuzzSwapFacility, FuzzMToken, FuzzJMIExtension {

    function fuzz_randomizeConfigs(
        uint256 baseEarnerRateSeed,
        uint256 baseMinterRateSeed,
        uint256 updateCollateralIntervalSeed,
        uint256 mintRatioSeed,
        uint256 penaltyRateSeed,
        uint256 minterFreezeTimeSeed
    ) public {
        require(!protocolSet);

        if (baseEarnerRateSeed % 5 == 0) {
            registrar.updateConfig(
                MAX_EARNER_RATE,
                fl.clamp(baseEarnerRateSeed, 0, ContinuousIndexingMath.BPS_SCALED_ONE, true)
            );
            registrar.updateConfig(
                BASE_MINTER_RATE,
                fl.clamp(baseMinterRateSeed, 0, ContinuousIndexingMath.BPS_SCALED_ONE, true)
            );
            registrar.updateConfig(TTGRegistrarReader.EARNER_RATE_MODEL, address(earnerRateModel));
            registrar.updateConfig(TTGRegistrarReader.MINTER_RATE_MODEL, address(minterRateModel));
            registrar.updateConfig(TTGRegistrarReader.UPDATE_COLLATERAL_VALIDATOR_THRESHOLD, 1);

            registrar.updateConfig(TTGRegistrarReader.UPDATE_COLLATERAL_INTERVAL, updateCollateralIntervalSeed);
            registrar.updateConfig(TTGRegistrarReader.MINT_DELAY, _mintDelay); //zeroes
            registrar.updateConfig(TTGRegistrarReader.MINT_TTL, _mintTtl);
            registrar.updateConfig(TTGRegistrarReader.MINT_RATIO, fl.clamp(mintRatioSeed, 0, 10_000, true));
            registrar.updateConfig(TTGRegistrarReader.PENALTY_RATE, fl.clamp(penaltyRateSeed, 0, 10_000, true));
            registrar.updateConfig(
                TTGRegistrarReader.MINTER_FREEZE_TIME,
                fl.clamp(minterFreezeTimeSeed, 0, 24 hours, true)
            );
        } else {
            // DEFAULT VALUES
            // uint32 internal _baseEarnerRate = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY
            // uint32 internal _baseMinterRate = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY
            // uint256 internal _updateInterval = 24 hours;
            // uint256 internal _mintDelay = 0;
            // uint256 internal _mintTtl = 0;
            // uint256 internal _mintRatio = 9_000; // 90%
            // uint32 internal _penaltyRate = 100; // 1%, bps
            // uint32 internal _minterFreezeTime = 24 hours;

            registrar.updateConfig(MAX_EARNER_RATE, _baseEarnerRate);
            registrar.updateConfig(BASE_MINTER_RATE, _baseMinterRate);
            registrar.updateConfig(TTGRegistrarReader.EARNER_RATE_MODEL, address(earnerRateModel));
            registrar.updateConfig(TTGRegistrarReader.MINTER_RATE_MODEL, address(minterRateModel));
            registrar.updateConfig(TTGRegistrarReader.UPDATE_COLLATERAL_VALIDATOR_THRESHOLD, 1);
            registrar.updateConfig(TTGRegistrarReader.UPDATE_COLLATERAL_INTERVAL, _updateInterval);
            registrar.updateConfig(TTGRegistrarReader.MINT_DELAY, _mintDelay);
            registrar.updateConfig(TTGRegistrarReader.MINT_TTL, _mintTtl);
            registrar.updateConfig(TTGRegistrarReader.MINT_RATIO, _mintRatio);
            registrar.updateConfig(TTGRegistrarReader.PENALTY_RATE, _penaltyRate);
            registrar.updateConfig(TTGRegistrarReader.MINTER_FREEZE_TIME, _minterFreezeTime);
        }

        protocolSet = true;
    }
}
