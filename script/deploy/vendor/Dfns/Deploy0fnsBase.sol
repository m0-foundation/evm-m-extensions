// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Upgrades } from "../../../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MEarnerManager } from "../../../../src/projects/earnerManager/MEarnerManager.sol";

import { DeployBase } from "../../DeployBase.s.sol";

abstract contract Deploy0fnsBase is DeployBase {
    string public constant NAME = "0fns";
    string public constant SYMBOL = "0fns";

    address public constant ADMIN = 0xba806d034Ec5337D85d3ACcC287f0660B0EBA1ea;
    address public constant EARNER_MANAGER = 0x82f48Bd6f9E235d7164ca11AD5D4A637b564ae3A;
    address public constant FEE_RECIPIENT = 0x272eED4EFA1A0F4F8aBb319E326a557a4F7008ce;

    function _deploy0fns(
        address deployer,
        address mToken,
        address swapFacility,
        string memory name,
        string memory symbol,
        address admin,
        address earnerManager,
        address feeRecipient
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        deployOptions.constructorData = abi.encode(address(mToken), address(swapFacility));

        implementation = Upgrades.deployImplementation("MEarnerManager.sol:MEarnerManager", deployOptions);

        bytes32 salt = _computeSalt(deployer, "EarnerEpsilon");

        proxy = _deployCreate3TransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(
                MEarnerManager.initialize.selector,
                name,
                symbol,
                admin,
                earnerManager,
                feeRecipient
            ),
            salt
        );

        proxyAdmin = Upgrades.getAdminAddress(proxy);
    }
}
