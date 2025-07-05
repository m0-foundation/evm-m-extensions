// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockRegistrar {
    constructor(address vault_) {
        vault = vault_;
    }

    address public vault;

    bytes32 public constant EARNERS_LIST_NAME = "earners";

    mapping(bytes32 key => bytes32 value) internal _values;

    mapping(bytes32 listName => mapping(address account => bool contains)) public listContainsMap;

    function listContains(bytes32 listName, address account) external view returns (bool contains) {
        return true; //mock approved minter
    }

    function get(bytes32 key) external view returns (bytes32 value) {
        return _values[key];
    }

    function set(bytes32 key, bytes32 value) external {
        _values[key] = value;
    }

    function setEarner(address account, bool contains) external {
        listContainsMap[EARNERS_LIST_NAME][account] = contains;
    }

    function updateConfig(bytes32 key_, address value_) external {
        _values[key_] = bytes32(uint256(uint160(value_)));
    }

    function updateConfig(bytes32 key_, uint256 value_) external {
        _values[key_] = bytes32(value_);
    }

    function updateConfig(bytes32 key_, bytes32 value_) external {
        _values[key_] = value_;
    }
}
