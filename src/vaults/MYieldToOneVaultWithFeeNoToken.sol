// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.26;

import { IMYieldToOne } from "../projects/yieldToOne/IMYieldToOne.sol";

import { MYieldToOneVaultWithFeeBase, IAsset } from "./MYieldToOneVaultWithFeeBase.sol";

abstract contract MYieldToOneVaultWithFeeNoTokenStorageLayout {
    /// @custom:storage-location erc7201:M0.storage.MYieldToOneVaultWithFeeNoToken
    struct MYieldToOneVaultWithFeeNoTokenStorageStruct {
        uint256 balancesTotal;
        mapping(address => uint256) balances;
    }

    // keccak256(abi.encode(uint256(keccak256("M0.storage.MYieldToOneVaultWithNoToken")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _M_YIELD_TO_ONE_VAULT_WITH_FEE_NO_TOKEN_STORAGE_LOCATION =
        0x9299d05662b275eb767cd9b38992e5264409040eb94aaa4fac7689d7ae429000;

    function _getMYieldToOneVaultWithFeeNoTokenStorageLocation()
        internal
        pure
        returns (MYieldToOneVaultWithFeeNoTokenStorageStruct storage $)
    {
        assembly {
            $.slot := _M_YIELD_TO_ONE_VAULT_WITH_FEE_NO_TOKEN_STORAGE_LOCATION
        }
    }
}

contract MYieldToOneVaultWithFeeNoToken is MYieldToOneVaultWithFeeNoTokenStorageLayout, MYieldToOneVaultWithFeeBase {
    error OnlyHolder();

    constructor(IAsset _asset) MYieldToOneVaultWithFeeBase(_asset) {
        _disableInitializers();
    }

    function initialize(address _admin, uint256 _fee) public initializer {
        __MYieldToOneVaultWithFeeBase_init(_admin, _fee);
    }

    function _totalIssued() internal view override returns (uint256) {
        MYieldToOneVaultWithFeeNoTokenStorageStruct storage $ = _getMYieldToOneVaultWithFeeNoTokenStorageLocation();

        return $.balancesTotal;
    }

    function _issue(address to, uint256 amount) internal override {
        MYieldToOneVaultWithFeeNoTokenStorageStruct storage $ = _getMYieldToOneVaultWithFeeNoTokenStorageLocation();

        $.balances[to] += amount;
    }

    function _claim(address from, uint256 amount) internal override {
        MYieldToOneVaultWithFeeNoTokenStorageStruct storage $ = _getMYieldToOneVaultWithFeeNoTokenStorageLocation();

        $.balances[from] -= amount;
    }

    function _balanceOf(address owner) internal view override returns (uint256) {
        MYieldToOneVaultWithFeeNoTokenStorageStruct storage $ = _getMYieldToOneVaultWithFeeNoTokenStorageLocation();

        return $.balances[owner];
    }
}
