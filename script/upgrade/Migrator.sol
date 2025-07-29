// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ERC1967Utils } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract Migrator {
    address public immutable newImplementation;

    constructor(address newImplementation_) {
        newImplementation = newImplementation_;
    }

    fallback() external virtual {
        // Prevent "Assembly access to immutable variables is not supported" error
        address newImplementation_ = newImplementation;
        bytes32 implementationSlot_ = ERC1967Utils.IMPLEMENTATION_SLOT;

        assembly {
            sstore(implementationSlot_, newImplementation_)
        }
    }
}
