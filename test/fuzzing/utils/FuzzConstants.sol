pragma solidity ^0.8.0;

contract FuzzConstants {
    // ==============================================================
    // ERC20 v4.9 ERRORS
    // ==============================================================
    bytes internal constant EXCEEDS_BALANCE_ERROR =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: transfer amount exceeds balance");
    bytes internal constant INSUFFICIENT_ALLOWANCE =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: insufficient allowance");
    bytes internal constant TRANSFER_FROM_ZERO =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: transfer from the zero address");
    bytes internal constant TRANSFER_TO_ZERO =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: transfer to the zero address");
    bytes internal constant APPROVE_TO_ZERO =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: approve to the zero address");
    bytes internal constant MINT_TO_ZERO =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: mint to the zero address");
    bytes internal constant BURN_FROM_ZERO =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: burn from the zero address");
    bytes internal constant DECREASED_ALLOWANCE =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: decreased allowance below zero");
    bytes internal constant BURN_EXCEEDS_BALANCE =
        abi.encodeWithSelector(bytes4(keccak256("Error(string)")), "ERC20: burn amount exceeds balance");

    // ==============================================================
    // PANIC CODES
    // ==============================================================
    uint256 internal constant PANIC_GENERAL = 0x00;
    uint256 internal constant PANIC_ASSERT = 0x01;
    uint256 internal constant PANIC_ARITHMETIC = 0x11;
    uint256 internal constant PANIC_DIVISION_BY_ZERO = 0x12;
    uint256 internal constant PANIC_ENUM_OUT_OF_BOUNDS = 0x21;
    uint256 internal constant PANIC_STORAGE_BYTES_ARRAY_ENCODING = 0x22;
    uint256 internal constant PANIC_POP_EMPTY_ARRAY = 0x31;
    uint256 internal constant PANIC_ARRAY_OUT_OF_BOUNDS = 0x32;
    uint256 internal constant PANIC_ALLOC_TOO_MUCH_MEMORY = 0x41;
    uint256 internal constant PANIC_ZERO_INIT_INTERNAL_FUNCTION = 0x51;
}
