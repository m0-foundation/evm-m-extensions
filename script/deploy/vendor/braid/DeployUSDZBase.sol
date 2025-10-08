// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Options } from "../../../../lib/openzeppelin-foundry-upgrades/src/Options.sol";
import { Upgrades } from "../../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { USDZ } from "../../../../src/vendor/braid/USDZ.sol";

import { DeployBase } from "../../DeployBase.s.sol";

abstract contract DeployUSDZBase is DeployBase {
    address public admin = 0x6931F096405a787aF1Ede966298c7A6e27e02B15;
    address public yieldRecipient = 0x602Ca3517e3D555ba966CFB3E3a489993A6e973d;
    address public yieldRecipientManager = admin;
    address public freezeManager = admin;
    address public forcedTransferManager = admin;
    address public pauser = admin;

    function _deployUSDZ(
        address deployer,
        address mToken,
        address swapFacility,
        address yieldRecipient,
        address admin,
        address freezeManager,
        address yieldRecipientManager,
        address pauser,
        address forcedTransferManager
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        deployOptions.constructorData = abi.encode(address(mToken), address(swapFacility));

        implementation = Upgrades.deployImplementation("USDZ.sol:USDZ", deployOptions);

        bytes32 salt = _computeSalt(deployer, "EarnerDelta");

        proxy = _deployCreate3TransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(
                USDZ.initialize.selector,
                yieldRecipient,
                admin,
                freezeManager,
                yieldRecipientManager,
                pauser,
                forcedTransferManager
            ),
            salt
        );

        proxyAdmin = Upgrades.getAdminAddress(proxy);
    }
}
