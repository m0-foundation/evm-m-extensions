// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PreconditionsBase.sol";

contract PreconditionsMToken is PreconditionsBase {
    function mintPreconditions(uint256 seed) public returns (address account, uint256 amount) {
        amount = fl.clamp(seed, 1, 100_000_000 * 1e6); // 100M MToken
        account = USERS[seed % USERS.length];
    }
}
