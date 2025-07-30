// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "forge-std/console.sol";

import { Options } from "../../lib/openzeppelin-foundry-upgrades/src/Options.sol";
import { Upgrades } from "../../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { TransparentUpgradeableProxy } from "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

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
        return bytes32(
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
        address deployer,
        address admin
    ) internal returns (address implementation, address proxy, address proxyAdmin) {

        // Deploy implementation directly since it has immutable variables
        implementation = address(new SwapFacility(M_TOKEN, REGISTRAR));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(
                SwapFacility.initialize.selector,
                admin
            ),
            _computeSalt(deployer, "SwapFacility02")
        );

        proxyAdmin = Upgrades.getAdminAddress(proxy);
    }

    function _deploySwapAdapter(
        address deployer,
        address admin
    ) internal returns (address implementation, address proxy, address proxyAdmin) {

        // Deploy implementation directly since it has immutable variables
        implementation = address(new UniswapV3SwapAdapter(M_TOKEN, _getSwapFacility(), UNISWAP_V3_ROUTER));

        proxy = _deployCreate3TransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(
                UniswapV3SwapAdapter.initialize.selector,
                admin,
                new address[](0)
            ),
            _computeSalt(deployer, "SwapAdapter01")
        );

        proxyAdmin = Upgrades.getAdminAddress(proxy);
        
    }

    function _deployMEarnerManager(
        address deployer,
        address admin
    ) internal returns (address implementation, address proxy, address proxyAdmin) {

        deployOptions.constructorData = abi.encode(M_TOKEN, _getSwapFacility());

        proxy = Upgrades.deployTransparentProxy(
            "MEarnerManager.sol:MEarnerManager",
            deployer,
            abi.encodeWithSelector(
                MEarnerManager.initialize.selector,
                _getName(),
                _getSymbol(),
                _getAdmin(),
                _getEarnerManager(),
                _getFeeRecipient()
            ),
            deployOptions
        );

        implementation = Upgrades.getImplementationAddress(proxy);
        proxyAdmin = Upgrades.getAdminAddress(proxy);

        return (implementation, proxy, proxyAdmin);
        
    }

    function _deployYieldToOne(
        address deployer,
        address admin
    ) internal returns (address implementation, address proxy, address proxyAdmin) {

        deployOptions.constructorData = abi.encode(
        M_TOKEN,
        _getSwapFacility()
        );

        proxy = Upgrades.deployTransparentProxy(
            "MYieldToOne.sol:MYieldToOne",
            deployer,
            abi.encodeWithSelector(
                MYieldToOne.initialize.selector, 
                _getName(), 
                _getSymbol(), 
                _getYieldRecipient(),
                _getAdmin(),
                _getBlacklistManager(), 
                _getYieldRecipientManager()
            ),
            deployOptions
        );

        implementation = Upgrades.getImplementationAddress(proxy);
        proxyAdmin = Upgrades.getAdminAddress(proxy);
            
    }

    function _deployYieldToAllWithFee(
        address deployer,
        address admin
    ) internal returns (address implementation, address proxy, address proxyAdmin) {

    deployOptions.constructorData = abi.encode(
      M_TOKEN,
      _getSwapFacility()
    );

    proxy = 
      Upgrades.deployTransparentProxy(
        "MYieldFee.sol:MYieldFee",
        deployer,
        abi.encodeWithSelector(
          MYieldFee.initialize.selector, 
          _getName(),
          _getSymbol(),
          _getFeeRate(),
          _getFeeRecipient(),
          _getAdmin(),
          _getFeeManager(),
          _getClaimRecipientManager()
        ),
        deployOptions
      );

      implementation = Upgrades.getImplementationAddress(proxy);
      proxyAdmin = Upgrades.getAdminAddress(proxy);

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
