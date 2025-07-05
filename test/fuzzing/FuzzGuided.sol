// SPDX-License-Identifier: UNTITLED
pragma solidity ^0.8.0;

import "./FuzzMYieldToOne.sol";
import "./FuzzMEarnerManager.sol";
import "./FuzzMYieldFee.sol";
import "./FuzzSwapFacility.sol";
import "./FuzzMToken.sol";

contract FuzzGuided is FuzzMYieldToOne, FuzzMEarnerManager, FuzzMYieldFee, FuzzSwapFacility, FuzzMToken {}
