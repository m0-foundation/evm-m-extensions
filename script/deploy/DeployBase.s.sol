// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { Options } from "../../lib/openzeppelin-foundry-upgrades/src/Options.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import {
    TransparentUpgradeableProxy
} from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ScriptBase } from "../ScriptBase.s.sol";
import { ICreateXLike } from "./interfaces/ICreateXLike.sol";

import { MEarnerManager } from "../../src/projects/earnerManager/MEarnerManager.sol";
import { MYieldToOne } from "../../src/projects/yieldToOne/MYieldToOne.sol";
import { MYieldFee } from "../../src/projects/yieldToAllWithFee/MYieldFee.sol";

import { SwapFacility } from "../../src/swap/SwapFacility.sol";
import { UniswapV3SwapAdapter } from "../../src/swap/UniswapV3SwapAdapter.sol";

contract DeployBase is ScriptBase {
    Options public deployOptions;

    // Same address across all supported mainnet and testnets networks.
    address internal constant _CREATE_X_FACTORY = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;

    function _computeSalt(address deployer_, string memory contractName_) internal pure returns (bytes32) {
        return
            bytes32(
                abi.encodePacked(
                    bytes20(deployer_), // used to implement permissioned deploy protection
                    bytes1(0), // disable cross-chain redeploy protection
                    bytes11(keccak256(bytes(contractName_)))
                )
            );
    }

    function _computeGuardedSalt(address deployer_, bytes32 salt_) internal pure returns (bytes32) {
        return _efficientHash({ a: bytes32(uint256(uint160(deployer_))), b: salt_ });
    }

    /**
     * @dev Returns the `keccak256` hash of `a` and `b` after concatenation.
     * @param a The first 32-byte value to be concatenated and hashed.
     * @param b The second 32-byte value to be concatenated and hashed.
     * @return hash The 32-byte `keccak256` hash of `a` and `b`.
     */
    function _efficientHash(bytes32 a, bytes32 b) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            mstore(0x00, a)
            mstore(0x20, b)
            hash := keccak256(0x00, 0x40)
        }
    }

    function _deploySwapFacility(
        address deployer
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        DeployConfig memory config = _getDeployConfig(block.chainid);

        implementation = address(new SwapFacility(config.mToken, config.registrar));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            config.admin,
            abi.encodeWithSelector(SwapFacility.initialize.selector, config.admin),
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
        address deployer,
        address admin
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
        address deployer,
        address admin
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
                extensionConfig.blacklistManager,
                extensionConfig.yieldRecipientManager
            ),
            _computeSalt(deployer, "MYieldToOne")
        );

        proxyAdmin = extensionConfig.admin;
    }

    function _deployYieldToAllWithFee(
        address deployer,
        address admin
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

    function _deployCreate3(bytes memory initCode_, bytes32 salt_) internal returns (address) {
        return ICreateXLike(_CREATE_X_FACTORY).deployCreate3(salt_, initCode_);
    }

    function _getCreate3Address(address deployer_, bytes32 salt_) internal view virtual returns (address) {
        return ICreateXLike(_CREATE_X_FACTORY).computeCreate3Address(_computeGuardedSalt(deployer_, salt_));
    }

    function _deployCreate3TransparentProxy(
        address implementation,
        address initialOwner,
        bytes memory initializerData,
        bytes32 salt
    ) internal returns (address) {
        return
            ICreateXLike(_CREATE_X_FACTORY).deployCreate3(
                salt,
                abi.encodePacked(
                    type(TransparentUpgradeableProxy).creationCode,
                    abi.encode(implementation, initialOwner, initializerData)
                )
            );
    }
}
