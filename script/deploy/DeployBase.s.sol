// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { DeployHelpers } from "../../lib/common/script/deploy/DeployHelpers.sol";

import { Options } from "../../lib/openzeppelin-foundry-upgrades/src/Options.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { ScriptBase } from "../ScriptBase.s.sol";

import { MEarnerManager } from "../../src/projects/earnerManager/MEarnerManager.sol";
import { MYieldToOne } from "../../src/projects/yieldToOne/MYieldToOne.sol";
import { MYieldFee } from "../../src/projects/yieldToAllWithFee/MYieldFee.sol";
import { JMIExtension } from "../../src/projects/jmi/JMIExtension.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";
import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";

contract DeployBase is DeployHelpers, ScriptBase {
    Options public deployOptions;

    function _deploySwapFacility(
        address deployer,
        address pauser
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        implementation = address(new SwapFacility(config.mToken, config.registrar));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            config.admin,
            abi.encodeWithSelector(SwapFacility.initialize.selector, config.admin, pauser),
            _computeSalt(deployer, "SwapFacility")
        );

        proxyAdmin = Upgrades.getAdminAddress(proxy);
    }

    function _deploySwapAdapter(address deployer) internal returns (address swapAdapter) {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        swapAdapter = _deployCreate3(
            abi.encodePacked(
                type(UniswapV3SwapAdapter).creationCode,
                abi.encode(
                    config.wrappedMToken,
                    _getSwapFacility(),
                    config.uniswapV3Router,
                    config.admin,
                    _getWhitelistedTokens(block.chainid)
                )
            ),
            _computeSalt(deployer, "SwapAdapter")
        );
    }

    function _deployMEarnerManager(
        address deployer
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        DeployExtensionConfig memory extensionConfig = _getExtensionConfig(block.chainid, _getExtensionName());

        implementation = address(new MEarnerManager(config.mToken, _getSwapFacility()));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            extensionConfig.admin,
            abi.encodeWithSelector(
                MEarnerManager.initialize.selector,
                extensionConfig.name,
                extensionConfig.symbol,
                extensionConfig.admin,
                extensionConfig.earnerManager,
                extensionConfig.feeRecipient
            ),
            _computeSalt(deployer, "MEarnerManager")
        );

        proxyAdmin = extensionConfig.admin;

        return (implementation, proxy, proxyAdmin);
    }

    function _deployYieldToOne(
        address deployer
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        DeployExtensionConfig memory extensionConfig = _getExtensionConfig(block.chainid, _getExtensionName());

        implementation = address(new MYieldToOne(config.mToken, _getSwapFacility()));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            extensionConfig.admin,
            abi.encodeWithSelector(
                MYieldToOne.initialize.selector,
                extensionConfig.name,
                extensionConfig.symbol,
                extensionConfig.yieldRecipient,
                extensionConfig.admin,
                extensionConfig.freezeManager,
                extensionConfig.yieldRecipientManager
            ),
            _computeSalt(deployer, "MYieldToOne")
        );

        proxyAdmin = extensionConfig.admin;
    }

    function _deployJMIExtension(
        address deployer
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        DeployExtensionConfig memory extensionConfig = _getExtensionConfig(block.chainid, _getExtensionName());

        implementation = address(new JMIExtension(config.mToken, _getSwapFacility()));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            extensionConfig.admin,
            abi.encodeWithSelector(
                JMIExtension.initialize.selector,
                extensionConfig.name,
                extensionConfig.symbol,
                extensionConfig.yieldRecipient,
                extensionConfig.admin,
                extensionConfig.freezeManager,
                extensionConfig.pauser,
                extensionConfig.yieldRecipientManager
            ),
            _computeSalt(deployer, "JMIExtension")
        );

        proxyAdmin = extensionConfig.admin;
    }

    function _deployYieldToAllWithFee(
        address deployer
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        DeployExtensionConfig memory extensionConfig = _getExtensionConfig(block.chainid, _getExtensionName());

        implementation = address(new MYieldFee(config.mToken, _getSwapFacility()));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            extensionConfig.admin,
            abi.encodeWithSelector(
                MYieldFee.initialize.selector,
                extensionConfig.name,
                extensionConfig.symbol,
                extensionConfig.feeRate,
                extensionConfig.feeRecipient,
                extensionConfig.admin,
                extensionConfig.feeManager,
                extensionConfig.claimRecipientManager
            ),
            _computeSalt(deployer, "MYieldFee")
        );

        proxyAdmin = extensionConfig.admin;

        return (implementation, proxy, proxyAdmin);
    }
}
