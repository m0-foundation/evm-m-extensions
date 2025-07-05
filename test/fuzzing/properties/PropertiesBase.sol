pragma solidity ^0.8.0;

import "@perimetersec/fuzzlib/src/FuzzBase.sol";
import "@perimetersec/fuzzlib/src/FuzzLibString.sol";
import "@perimetersec/fuzzlib/src/FuzzBase.sol";

import "./PropertiesDescriptions.sol";
import "../helpers/BeforeAfter.sol";
import "../utils/FuzzConstants.sol";

import {stdMath} from "forge-std/StdMath.sol";

contract PropertiesBase is PropertiesDescriptions, BeforeAfter, FuzzConstants {
    // ==============================================================
    // Helpers
    // ==============================================================

    function assertApproxEq(uint256 a, uint256 b, uint256 maxDelta, string memory reason) internal {
        uint256 dt;
        if (a >= b) dt = a - b;
        else dt = b - a;
        if (dt > maxDelta) {
            bytes memory aBytes = abi.encodePacked(a);
            bytes memory bBytes = abi.encodePacked(b);
            string memory aStr = FuzzLibString.toHexString(aBytes);
            string memory bStr = FuzzLibString.toHexString(bBytes);
            fl.log("Error: a =~ b not satisfied [uint]");
            fl.log("   Value a", a);
            fl.log("   Value b", b);
            fl.log(" Max Delta", maxDelta);
            fl.log("     Delta", dt);
            fl.t(false, reason);
        }
    }

    function assertApproxEq(int256 a, int256 b, int256 maxDelta, string memory reason) internal {
        int256 dt;
        if (a >= b) dt = a - b;
        else dt = b - a;
        if (dt > maxDelta) {
            bytes memory aBytes = abi.encodePacked(a);
            bytes memory bBytes = abi.encodePacked(b);
            string memory aStr = FuzzLibString.toHexString(aBytes);
            string memory bStr = FuzzLibString.toHexString(bBytes);
            fl.log("Error: a =~ b not satisfied [uint]");
            fl.log("   Value a", a);
            fl.log("   Value b", b);
            fl.log(" Max Delta", maxDelta);
            fl.log("     Delta", dt);
            fl.t(false, reason);
        }
    }

    function greaterThanOrEqualWithToleranceWei(uint256 a, uint256 b, uint256 maxWeiDiff, string memory reason)
        internal
    {
        if (a >= b) {
            fl.t(true, "Invariant ok, checked for: ");
            fl.log(reason);
            fl.log("a is greater than or equal to b");
            return;
        }

        uint256 diff = b - a;

        if (diff > maxWeiDiff) {
            fl.log("a: ", a);
            fl.log("b: ", b);
            fl.log("Difference in wei is bigger than expected", diff);
            fl.t(false, reason);
        } else {
            fl.t(true, "Invariant ok, checked for: ");
            fl.log(reason);
            fl.log("Difference in wei: ", diff);
        }
    }

    function isApproxEqRel(uint256 a, uint256 b, uint256 maxDelta, string memory reason) internal returns (bool) {
        a < b ? b = a : a = b;
        uint256 delta = stdMath.percentDelta(a, b);
        fl.log("a: ", a);
        fl.log("b: ", b);
        fl.log("Difference % is bigger than expected", delta);
        if (delta > maxDelta) fl.t(false, reason);
    }
}
