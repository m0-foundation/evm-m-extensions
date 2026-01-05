// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// lib/common/src/libs/Bytes32String.sol

/**
 * @title  A library to convert between string and bytes32 (assuming 32 characters or less).
 * @author M^0 Labs
 */
library Bytes32String {
    function toBytes32(string memory input) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked(input));
    }

    function toString(bytes32 input) internal pure returns (string memory) {
        uint256 length;

        while (length < 32 && uint8(input[length]) != 0) {
            ++length;
        }

        bytes memory name = new bytes(length);

        for (uint256 index; index < length; ++index) {
            name[index] = input[index];
        }

        return string(name);
    }
}

// src/interfaces/IContinuousIndexing.sol

/**
 * @title  Continuous Indexing Interface.
 * @author M^0 Labs
 */
interface IContinuousIndexing {
    /* ============ Events ============ */

    /**
     * @notice Emitted when the index is updated.
     * @param  index The new index.
     * @param  rate  The current rate.
     */
    event IndexUpdated(uint128 indexed index, uint32 indexed rate);

    /* ============ Interactive Functions ============ */

    /**
     * @notice Updates the latest index and latest accrual time in storage.
     * @return index The new stored index for computing present amounts from principal amounts.
     */
    function updateIndex() external returns (uint128);

    /* ============ View/Pure Functions ============ */

    /// @notice The current index that would be written to storage if `updateIndex` is called.
    function currentIndex() external view returns (uint128);

    /// @notice The latest updated index.
    function latestIndex() external view returns (uint128);

    /// @notice The latest timestamp when the index was updated.
    function latestUpdateTimestamp() external view returns (uint40);
}

// lib/common/src/interfaces/IERC1271.sol

/**
 * @title  Standard Signature Validation Method for Contracts via EIP-1271.
 * @author M^0 Labs
 * @dev    The interface as defined by EIP-1271: https://eips.ethereum.org/EIPS/eip-1271
 */
interface IERC1271 {
    /**
     * @dev    Returns a specific magic value if the provided signature is valid for the provided digest.
     * @param  digest     Hash of the data purported to have been signed.
     * @param  signature  Signature byte array associated with the digest.
     * @return magicValue Magic value 0x1626ba7e if the signature is valid.
     */
    function isValidSignature(bytes32 digest, bytes memory signature) external view returns (bytes4 magicValue);
}

// lib/common/src/interfaces/IERC20.sol

/**
 * @title  ERC20 Token Standard.
 * @author M^0 Labs
 * @dev    The interface as defined by EIP-20: https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    /* ============ Events ============ */

    /**
     * @notice Emitted when `spender` has been approved for `amount` of the token balance of `account`.
     * @param  account The address of the account.
     * @param  spender The address of the spender being approved for the allowance.
     * @param  amount  The amount of the allowance being approved.
     */
    event Approval(address indexed account, address indexed spender, uint256 amount);

    /**
     * @notice Emitted when `amount` tokens is transferred from `sender` to `recipient`.
     * @param  sender    The address of the sender who's token balance is decremented.
     * @param  recipient The address of the recipient who's token balance is incremented.
     * @param  amount    The amount of tokens being transferred.
     */
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    /* ============ Interactive Functions ============ */

    /**
     * @notice Allows a calling account to approve `spender` to spend up to `amount` of its token balance.
     * @dev    MUST emit an `Approval` event.
     * @param  spender The address of the account being allowed to spend up to the allowed amount.
     * @param  amount  The amount of the allowance being approved.
     * @return Whether or not the approval was successful.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Allows a calling account to transfer `amount` tokens to `recipient`.
     * @param  recipient The address of the recipient who's token balance will be incremented.
     * @param  amount    The amount of tokens being transferred.
     * @return Whether or not the transfer was successful.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Allows a calling account to transfer `amount` tokens from `sender`, with allowance, to a `recipient`.
     * @param  sender    The address of the sender who's token balance will be decremented.
     * @param  recipient The address of the recipient who's token balance will be incremented.
     * @param  amount    The amount of tokens being transferred.
     * @return Whether or not the transfer was successful.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns the allowance `spender` is allowed to spend on behalf of `account`.
     * @param  account The address of the account who's token balance `spender` is allowed to spend.
     * @param  spender The address of an account allowed to spend on behalf of `account`.
     * @return The amount `spender` can spend on behalf of `account`.
     */
    function allowance(address account, address spender) external view returns (uint256);

    /**
     * @notice Returns the token balance of `account`.
     * @param  account The address of some account.
     * @return The token balance of `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals UIs should assume all amounts have.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the contract/token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the current total supply of the token.
    function totalSupply() external view returns (uint256);
}

// lib/common/src/interfaces/IERC712.sol

/**
 * @title  Typed structured data hashing and signing via EIP-712.
 * @author M^0 Labs
 * @dev    The interface as defined by EIP-712: https://eips.ethereum.org/EIPS/eip-712
 */
interface IERC712 {
    /* ============ Custom Errors ============ */

    /// @notice Revert message when an invalid signature is detected.
    error InvalidSignature();

    /// @notice Revert message when a signature with invalid length is detected.
    error InvalidSignatureLength();

    /// @notice Revert message when the S portion of a signature is invalid.
    error InvalidSignatureS();

    /// @notice Revert message when the V portion of a signature is invalid.
    error InvalidSignatureV();

    /**
     * @notice Revert message when a signature is being used beyond its deadline (i.e. expiry).
     * @param  deadline  The last timestamp where the signature is still valid.
     * @param  timestamp The current timestamp.
     */
    error SignatureExpired(uint256 deadline, uint256 timestamp);

    /// @notice Revert message when a recovered signer does not match the account being purported to have signed.
    error SignerMismatch();

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the EIP712 domain separator used in the encoding of a signed digest.
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// src/interfaces/IRateModel.sol

/**
 * @title  Rate Model Interface.
 * @author M^0 Labs
 */
interface IRateModel {
    /**
     * @notice Returns the current yearly rate in BPS.
     *         This value does not account for the compounding interest.
     */
    function rate() external view returns (uint256);
}

// src/interfaces/ITTGRegistrar.sol

/**
 * @title  TTG (Two Token Governance) Registrar interface.
 * @author M^0 Labs
 */
interface ITTGRegistrar {
    /**
     * @notice Key value pair getter.
     * @param  key The key to get the value of.
     * @return value The value of the key.
     */
    function get(bytes32 key) external view returns (bytes32 value);

    /**
     * @notice Checks if the list contains the account.
     * @param  list The list to check.
     * @param  account The account to check.
     * @return True if the list contains the account, false otherwise.
     */
    function listContains(bytes32 list, address account) external view returns (bool);

    /// @notice Returns the vault contract address.
    function vault() external view returns (address);
}

// lib/common/src/libs/UIntMath.sol

/**
 * @title  Library to perform safe math operations on uint types
 * @author M^0 Labs
 */
library UIntMath {
    /* ============ Custom Errors ============ */

    /// @notice Emitted when a passed value is greater than the maximum value of uint16.
    error InvalidUInt16();

    /// @notice Emitted when a passed value is greater than the maximum value of uint32.
    error InvalidUInt32();

    /// @notice Emitted when a passed value is greater than the maximum value of uint40.
    error InvalidUInt40();

    /// @notice Emitted when a passed value is greater than the maximum value of uint48.
    error InvalidUInt48();

    /// @notice Emitted when a passed value is greater than the maximum value of uint112.
    error InvalidUInt112();

    /// @notice Emitted when a passed value is greater than the maximum value of uint128.
    error InvalidUInt128();

    /// @notice Emitted when a passed value is greater than the maximum value of uint240.
    error InvalidUInt240();

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @notice Casts a uint256 value to a uint16, ensuring that it is less than or equal to the maximum uint16 value.
     * @param  n The value to cast.
     * @return The value casted to uint16.
     */
    function safe16(uint256 n) internal pure returns (uint16) {
        if (n > type(uint16).max) revert InvalidUInt16();
        return uint16(n);
    }

    /**
     * @notice Casts a uint256 value to a uint32, ensuring that it is less than or equal to the maximum uint32 value.
     * @param  n The value to cast.
     * @return The value casted to uint32.
     */
    function safe32(uint256 n) internal pure returns (uint32) {
        if (n > type(uint32).max) revert InvalidUInt32();
        return uint32(n);
    }

    /**
     * @notice Casts a uint256 value to a uint40, ensuring that it is less than or equal to the maximum uint40 value.
     * @param  n The value to cast.
     * @return The value casted to uint40.
     */
    function safe40(uint256 n) internal pure returns (uint40) {
        if (n > type(uint40).max) revert InvalidUInt40();
        return uint40(n);
    }

    /**
     * @notice Casts a uint256 value to a uint48, ensuring that it is less than or equal to the maximum uint48 value.
     * @param  n The value to cast.
     * @return The value casted to uint48.
     */
    function safe48(uint256 n) internal pure returns (uint48) {
        if (n > type(uint48).max) revert InvalidUInt48();
        return uint48(n);
    }

    /**
     * @notice Casts a uint256 value to a uint112, ensuring that it is less than or equal to the maximum uint112 value.
     * @param  n The value to cast.
     * @return The value casted to uint112.
     */
    function safe112(uint256 n) internal pure returns (uint112) {
        if (n > type(uint112).max) revert InvalidUInt112();
        return uint112(n);
    }

    /**
     * @notice Casts a uint256 value to a uint128, ensuring that it is less than or equal to the maximum uint128 value.
     * @param  n The value to cast.
     * @return The value casted to uint128.
     */
    function safe128(uint256 n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    /**
     * @notice Casts a uint256 value to a uint240, ensuring that it is less than or equal to the maximum uint240 value.
     * @param  n The value to cast.
     * @return The value casted to uint240.
     */
    function safe240(uint256 n) internal pure returns (uint240) {
        if (n > type(uint240).max) revert InvalidUInt240();
        return uint240(n);
    }

    /**
     * @notice Limits a uint256 value to the maximum uint32 value.
     * @param  n The value to bound.
     * @return The value limited to within uint32 bounds.
     */
    function bound32(uint256 n) internal pure returns (uint32) {
        return uint32(min256(n, uint256(type(uint32).max)));
    }

    /**
     * @notice Limits a uint256 value to the maximum uint112 value.
     * @param  n The value to bound.
     * @return The value limited to within uint112 bounds.
     */
    function bound112(uint256 n) internal pure returns (uint112) {
        return uint112(min256(n, uint256(type(uint112).max)));
    }

    /**
     * @notice Limits a uint256 value to the maximum uint128 value.
     * @param  n The value to bound.
     * @return The value limited to within uint128 bounds.
     */
    function bound128(uint256 n) internal pure returns (uint128) {
        return uint128(min256(n, uint256(type(uint128).max)));
    }

    /**
     * @notice Limits a uint256 value to the maximum uint240 value.
     * @param  n The value to bound.
     * @return The value limited to within uint240 bounds.
     */
    function bound240(uint256 n) internal pure returns (uint240) {
        return uint240(min256(n, uint256(type(uint240).max)));
    }

    /**
     * @notice Compares two uint32 values and returns the larger one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The larger value.
     */
    function max32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a > b ? a : b;
    }

    /**
     * @notice Compares two uint40 values and returns the larger one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The larger value.
     */
    function max40(uint40 a, uint40 b) internal pure returns (uint40) {
        return a > b ? a : b;
    }

    /**
     * @notice Compares two uint128 values and returns the larger one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The larger value.
     */
    function max128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a > b ? a : b;
    }

    /**
     * @notice Compares two uint240 values and returns the larger one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The larger value.
     */
    function max240(uint240 a, uint240 b) internal pure returns (uint240) {
        return a > b ? a : b;
    }

    /**
     * @notice Compares two uint32 values and returns the lesser one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The lesser value.
     */
    function min32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /**
     * @notice Compares two uint40 values and returns the lesser one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The lesser value.
     */
    function min40(uint40 a, uint40 b) internal pure returns (uint40) {
        return a < b ? a : b;
    }

    /**
     * @notice Compares two uint240 values and returns the lesser one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The lesser value.
     */
    function min240(uint240 a, uint240 b) internal pure returns (uint240) {
        return a < b ? a : b;
    }

    /**
     * @notice Compares two uint112 values and returns the lesser one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The lesser value.
     */
    function min112(uint112 a, uint112 b) internal pure returns (uint112) {
        return a < b ? a : b;
    }

    /**
     * @notice Compares two uint256 values and returns the lesser one.
     * @param  a Value to compare.
     * @param  b Value to compare.
     * @return The lesser value.
     */
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// src/libs/ContinuousIndexingMath.sol

/**
 * @title  Arithmetic library with operations for calculating continuous indexing.
 * @author M^0 Labs
 */
library ContinuousIndexingMath {
    /* ============ Variables ============ */

    /// @notice The number of seconds in a year.
    uint32 internal constant SECONDS_PER_YEAR = 31_536_000;

    /// @notice 100% in basis points.
    uint16 internal constant BPS_SCALED_ONE = 1e4;

    /// @notice The scaling of rates in for exponent math.
    uint56 internal constant EXP_SCALED_ONE = 1e12;

    /* ============ Custom Errors ============ */

    /// @notice Emitted when a division by zero occurs.
    error DivisionByZero();

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @notice Helper function to calculate `(x * EXP_SCALED_ONE) / index`, rounded down.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function divideDown(uint240 x, uint128 index) internal pure returns (uint112 z) {
        if (index == 0) revert DivisionByZero();

        unchecked {
            // NOTE: While `uint256(x) * EXP_SCALED_ONE` can technically overflow, these divide/multiply functions are
            //       only used for the purpose of principal/present amount calculations for continuous indexing, and
            //       so for an `x` to be large enough to overflow this, it would have to be a possible result of
            //       `multiplyDown` or `multiplyUp`, which would already satisfy
            //       `uint256(x) * EXP_SCALED_ONE < type(uint240).max`.
            return UIntMath.safe112((uint256(x) * EXP_SCALED_ONE) / index);
        }
    }

    /**
     * @notice Helper function to calculate `(x * EXP_SCALED_ONE) / index`, rounded up.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function divideUp(uint240 x, uint128 index) internal pure returns (uint112 z) {
        if (index == 0) revert DivisionByZero();

        unchecked {
            // NOTE: While `uint256(x) * EXP_SCALED_ONE` can technically overflow, these divide/multiply functions are
            //       only used for the purpose of principal/present amount calculations for continuous indexing, and
            //       so for an `x` to be large enough to overflow this, it would have to be a possible result of
            //       `multiplyDown` or `multiplyUp`, which would already satisfy
            //       `uint256(x) * EXP_SCALED_ONE < type(uint240).max`.
            return UIntMath.safe112(((uint256(x) * EXP_SCALED_ONE) + index - 1) / index);
        }
    }

    /**
     * @notice Helper function to calculate `(x * index) / EXP_SCALED_ONE`, rounded down.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function multiplyDown(uint112 x, uint128 index) internal pure returns (uint240 z) {
        unchecked {
            return uint240((uint256(x) * index) / EXP_SCALED_ONE);
        }
    }

    /**
     * @notice Helper function to calculate `(x * index) / EXP_SCALED_ONE`, rounded up.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function multiplyUp(uint112 x, uint128 index) internal pure returns (uint240 z) {
        unchecked {
            return uint240(((uint256(x) * index) + (EXP_SCALED_ONE - 1)) / EXP_SCALED_ONE);
        }
    }

    /**
     * @notice Helper function to calculate `(index * deltaIndex) / EXP_SCALED_ONE`, rounded down.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function multiplyIndicesDown(uint128 index, uint48 deltaIndex) internal pure returns (uint144 z) {
        unchecked {
            return uint144((uint256(index) * deltaIndex) / EXP_SCALED_ONE);
        }
    }

    /**
     * @notice Helper function to calculate `(index * deltaIndex) / EXP_SCALED_ONE`, rounded up.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function multiplyIndicesUp(uint128 index, uint48 deltaIndex) internal pure returns (uint144 z) {
        unchecked {
            return uint144((uint256(index) * deltaIndex + (EXP_SCALED_ONE - 1)) / EXP_SCALED_ONE);
        }
    }

    /**
     * @notice Helper function to calculate e^rt (continuous compounding formula).
     * @dev    `uint64 yearlyRate` can accommodate 1000% interest per year.
     * @dev    `uint32 time` can accommodate 100 years.
     * @dev    `type(uint64).max * type(uint32).max / SECONDS_PER_YEAR` fits in a `uint72`.
     */
    function getContinuousIndex(uint64 yearlyRate, uint32 time) internal pure returns (uint48 index) {
        unchecked {
            // NOTE: Casting `uint256(yearlyRate) * time` to a `uint72` is safe because the largest value is
            //      `type(uint64).max * type(uint32).max / SECONDS_PER_YEAR`, which is less than `type(uint72).max`.
            return exponent(uint72((uint256(yearlyRate) * time) / SECONDS_PER_YEAR));
        }
    }

    /**
     * @notice Helper function to calculate y = e^x using R(4,4) Padé approximation:
     *           e(x) = (1 + x/2 + 3(x^2)/28 + x^3/84 + x^4/1680) / (1 - x/2 + 3(x^2)/28 - x^3/84 + x^4/1680)
     *           See: https://en.wikipedia.org/wiki/Pad%C3%A9_table
     *           See: https://www.wolframalpha.com/input?i=PadeApproximant%5Bexp%5Bx%5D%2C%7Bx%2C0%2C%7B4%2C+4%7D%7D%5D
     *         Despite itself being a whole number, `x` represents a real number scaled by `EXP_SCALED_ONE`, thus
     *         allowing for y = e^x where x is a real number.
     * @dev    Output `y` for a `uint72` input `x` will fit in `uint48`
     */
    function exponent(uint72 x) internal pure returns (uint48 y) {
        // NOTE: This can be done unchecked even for `x = type(uint72).max`.
        //       Verify by removing `unchecked` and running `test_exponent()`.
        unchecked {
            uint256 x2 = uint256(x) * x;

            // `additiveTerms` is `(1 + 3(x^2)/28 + x^4/1680)`, and scaled by `84e27`.
            // NOTE: `84e27` the cleanest and largest scalar, given the various intermediate overflow possibilities.
            // NOTE: The resulting `(x2 * x2) / 20e21` term has been split up in order to avoid overflow of `x2 * x2`.
            uint256 additiveTerms = 84e27 + (9e3 * x2) + ((x2 / 2e11) * (x2 / 1e11));

            // `differentTerms` is `(- x/2 - x^3/84)`, but positive (will be subtracted later), and scaled by `84e27`.
            uint256 differentTerms = uint256(x) * (42e15 + (x2 / 1e9));

            // Result needs to be scaled by `1e12`.
            // NOTE: Can cast to `uint48` because contents can never be larger than `type(uint48).max` for any `x`.
            //       Max `y` is ~200e12, before falling off. See links above for reference.
            return uint48(((additiveTerms + differentTerms) * 1e12) / (additiveTerms - differentTerms));
        }
    }

    /**
     * @notice Helper function to convert 12-decimal representation to basis points.
     * @param  input The input in 12-decimal representation.
     * @return The output in basis points.
     */
    function convertToBasisPoints(uint64 input) internal pure returns (uint40) {
        unchecked {
            return uint40((uint256(input) * BPS_SCALED_ONE) / EXP_SCALED_ONE);
        }
    }

    /**
     * @notice Helper function to convert basis points to 12-decimal representation.
     * @param  input The input in basis points.
     * @return The output in 12-decimal representation.
     */
    function convertFromBasisPoints(uint32 input) internal pure returns (uint64) {
        unchecked {
            return uint64((uint256(input) * EXP_SCALED_ONE) / BPS_SCALED_ONE);
        }
    }
}

// lib/common/src/interfaces/IERC712Extended.sol

/**
 * @title  EIP-712 extended by EIP-5267.
 * @author M^0 Labs
 * @dev    The additional interface as defined by EIP-5267: https://eips.ethereum.org/EIPS/eip-5267
 */
interface IERC712Extended is IERC712 {
    /* ============ Events ============ */

    /// @notice MAY be emitted to signal that the domain could have changed.
    event EIP712DomainChanged();

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the fields and values that describe the domain separator used by this contract for EIP-712.
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// lib/common/src/libs/SignatureChecker.sol

/**
 * @title  A library to handle ECDSA/secp256k1 and ERC1271 signatures, individually or in arbitrarily in combination.
 * @author M^0 Labs
 */
library SignatureChecker {
    /* ============ Enums ============ */

    /**
     * @notice An enum representing the possible errors that can be emitted during signature validation.
     * @param  NoError                No error occurred during signature validation.
     * @param  InvalidSignature       The signature is invalid.
     * @param  InvalidSignatureLength The signature length is invalid.
     * @param  InvalidSignatureS      The signature parameter S is invalid.
     * @param  InvalidSignatureV      The signature parameter V is invalid.
     * @param  SignerMismatch         The signer does not match the recovered signer.
     */
    enum Error {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV,
        SignerMismatch
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns whether a signature is valid (ECDSA/secp256k1 or ERC1271) for a signer and digest.
     * @dev    Signatures must not be used as unique identifiers since the `ecrecover` EVM opcode
     *         allows for malleable (non-unique) signatures.
     *         See https://github.com/OpenZeppelin/openzeppelin-contracts/security/advisories/GHSA-4h98-2769-gh6h
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array signature.
     * @return           Whether the signature is valid or not.
     */
    function isValidSignature(address signer, bytes32 digest, bytes memory signature) internal view returns (bool) {
        return isValidECDSASignature(signer, digest, signature) || isValidERC1271Signature(signer, digest, signature);
    }

    /**
     * @dev    Returns whether an ERC1271 signature is valid for a signer and digest.
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ERC1271 signature.
     * @return           Whether the signature is valid or not.
     */
    function isValidERC1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success_, bytes memory result_) = signer.staticcall(
            abi.encodeCall(IERC1271.isValidSignature, (digest, signature))
        );

        return
            success_ &&
            result_.length >= 32 &&
            abi.decode(result_, (bytes32)) == bytes32(IERC1271.isValidSignature.selector);
    }

    /**
     * @dev    Decodes an ECDSA/secp256k1 signature from a byte array to standard v, r, and s parameters.
     * @param  signature A byte array ECDSA/secp256k1 signature.
     * @return v         An ECDSA/secp256k1 signature parameter.
     * @return r         An ECDSA/secp256k1 signature parameter.
     * @return s         An ECDSA/secp256k1 signature parameter.
     */
    function decodeECDSASignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // ecrecover takes the signature parameters, and they can be decoded using assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    /**
     * @dev    Decodes an ECDSA/secp256k1 short signature as defined by EIP2098
     *         from a byte array to standard v, r, and s parameters.
     * @param  signature A byte array ECDSA/secp256k1 short signature.
     * @return r         An ECDSA/secp256k1 signature parameter.
     * @return vs        An ECDSA/secp256k1 short signature parameter.
     */
    function decodeShortECDSASignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 vs) {
        // ecrecover takes the signature parameters, and they can be decoded using assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(signature, 0x20))
            vs := mload(add(signature, 0x40))
        }
    }

    /**
     * @dev    Returns whether an ECDSA/secp256k1 signature is valid for a signer and digest.
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ECDSA/secp256k1 signature (encoded r, s, v).
     * @return           Whether the signature is valid or not.
     */
    function isValidECDSASignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (bool) {
        if (signature.length == 64) {
            (bytes32 r, bytes32 vs) = decodeShortECDSASignature(signature);
            return isValidECDSASignature(signer, digest, r, vs);
        }

        return validateECDSASignature(signer, digest, signature) == Error.NoError;
    }

    /**
     * @dev    Returns whether an ECDSA/secp256k1 short signature is valid for a signer and digest.
     * @param  signer The address of the account purported to have signed.
     * @param  digest The hash of the data that was signed.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  vs     An ECDSA/secp256k1 short signature parameter.
     * @return        Whether the signature is valid or not.
     */
    function isValidECDSASignature(address signer, bytes32 digest, bytes32 r, bytes32 vs) internal pure returns (bool) {
        return validateECDSASignature(signer, digest, r, vs) == Error.NoError;
    }

    /**
     * @dev    Returns the signer of an ECDSA/secp256k1 signature for some digest.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ECDSA/secp256k1 signature.
     * @return           An error, if any, that occurred during the signer recovery.
     * @return           The address of the account recovered form the signature (0 if error).
     */
    function recoverECDSASigner(bytes32 digest, bytes memory signature) internal pure returns (Error, address) {
        if (signature.length != 65) return (Error.InvalidSignatureLength, address(0));

        (uint8 v, bytes32 r, bytes32 s) = decodeECDSASignature(signature);

        return recoverECDSASigner(digest, v, r, s);
    }

    /**
     * @dev    Returns the signer of an ECDSA/secp256k1 short signature for some digest.
     * @dev    See https://eips.ethereum.org/EIPS/eip-2098
     * @param  digest The hash of the data that was signed.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  vs     An ECDSA/secp256k1 short signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     * @return        The address of the account recovered form the signature (0 if error).
     */
    function recoverECDSASigner(bytes32 digest, bytes32 r, bytes32 vs) internal pure returns (Error, address) {
        unchecked {
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            return recoverECDSASigner(digest, v, r, s);
        }
    }

    /**
     * @dev    Returns the signer of an ECDSA/secp256k1 signature for some digest.
     * @param  digest The hash of the data that was signed.
     * @param  v      An ECDSA/secp256k1 signature parameter.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  s      An ECDSA/secp256k1 signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     * @return signer The address of the account recovered form the signature (0 if error).
     */
    function recoverECDSASigner(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (Error, address signer) {
        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        if (uint256(s) > uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0))
            return (Error.InvalidSignatureS, address(0));

        if (v != 27 && v != 28) return (Error.InvalidSignatureV, address(0));

        signer = ecrecover(digest, v, r, s);

        return (signer == address(0)) ? (Error.InvalidSignature, address(0)) : (Error.NoError, signer);
    }

    /**
     * @dev    Returns an error, if any, in validating an ECDSA/secp256k1 signature for a signer and digest.
     * @param  signer    The address of the account purported to have signed.
     * @param  digest    The hash of the data that was signed.
     * @param  signature A byte array ERC1271 signature.
     * @return           An error, if any, that occurred during the signer recovery.
     */
    function validateECDSASignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (Error) {
        (Error recoverError, address recoveredSigner) = recoverECDSASigner(digest, signature);

        return (recoverError == Error.NoError) ? validateRecoveredSigner(signer, recoveredSigner) : recoverError;
    }

    /**
     * @dev    Returns an error, if any, in validating an ECDSA/secp256k1 short signature for a signer and digest.
     * @param  signer The address of the account purported to have signed.
     * @param  digest The hash of the data that was signed.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  vs     An ECDSA/secp256k1 short signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     */
    function validateECDSASignature(
        address signer,
        bytes32 digest,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (Error) {
        (Error recoverError, address recoveredSigner) = recoverECDSASigner(digest, r, vs);

        return (recoverError == Error.NoError) ? validateRecoveredSigner(signer, recoveredSigner) : recoverError;
    }

    /**
     * @dev    Returns an error, if any, in validating an ECDSA/secp256k1 signature for a signer and digest.
     * @param  signer The address of the account purported to have signed.
     * @param  digest The hash of the data that was signed.
     * @param  v      An ECDSA/secp256k1 signature parameter.
     * @param  r      An ECDSA/secp256k1 signature parameter.
     * @param  s      An ECDSA/secp256k1 signature parameter.
     * @return        An error, if any, that occurred during the signer recovery.
     */
    function validateECDSASignature(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (Error) {
        (Error recoverError, address recoveredSigner) = recoverECDSASigner(digest, v, r, s);

        return (recoverError == Error.NoError) ? validateRecoveredSigner(signer, recoveredSigner) : recoverError;
    }

    /**
     * @dev    Returns an error if `signer` is not `recoveredSigner`.
     * @param  signer          The address of the some signer.
     * @param  recoveredSigner The address of the some recoveredSigner.
     * @return                 An error if `signer` is not `recoveredSigner`.
     */
    function validateRecoveredSigner(address signer, address recoveredSigner) internal pure returns (Error) {
        return (signer == recoveredSigner) ? Error.NoError : Error.SignerMismatch;
    }
}

// src/libs/TTGRegistrarReader.sol

/**
 * @title  Library to read TTG (Two Token Governance) Registrar contract parameters.
 * @author M^0 Labs
 */
library TTGRegistrarReader {
    /* ============ Variables ============ */

    /// @notice The name of parameter in TTG that defines the earner rate model contract.
    bytes32 internal constant EARNER_RATE_MODEL = "earner_rate_model";

    /// @notice The parameter name in TTG that defines the earners list.
    bytes32 internal constant EARNERS_LIST = "earners";

    /// @notice The parameter name in TTG that defines whether to ignore the earners list or not.
    bytes32 internal constant EARNERS_LIST_IGNORED = "earners_list_ignored";

    /// @notice The parameter name in TTG that defines the time to wait for mint request to be processed.
    bytes32 internal constant MINT_DELAY = "mint_delay";

    /// @notice The parameter name in TTG that defines the mint ratio.
    bytes32 internal constant MINT_RATIO = "mint_ratio"; // bps

    /// @notice The parameter name in TTG that defines the time while mint request can still be processed.
    bytes32 internal constant MINT_TTL = "mint_ttl";

    /// @notice The parameter name in TTG that defines the time to freeze minter.
    bytes32 internal constant MINTER_FREEZE_TIME = "minter_freeze_time";

    /// @notice The parameter name in TTG that defines the minter rate model contract.
    bytes32 internal constant MINTER_RATE_MODEL = "minter_rate_model";

    /// @notice The parameter name in TTG that defines the minters list.
    bytes32 internal constant MINTERS_LIST = "minters";

    /// @notice The parameter name in TTG that defines the penalty rate.
    bytes32 internal constant PENALTY_RATE = "penalty_rate"; // bps

    /// @notice The parameter name in TTG that defines the required interval to update collateral.
    bytes32 internal constant UPDATE_COLLATERAL_INTERVAL = "update_collateral_interval";

    /// @notice The parameter name that defines number of signatures required for successful collateral update.
    bytes32 internal constant UPDATE_COLLATERAL_VALIDATOR_THRESHOLD = "update_collateral_threshold";

    /// @notice The parameter name in TTG that defines the validators list.
    bytes32 internal constant VALIDATORS_LIST = "validators";

    /* ============ Internal View/Pure Functions ============ */

    /// @notice Gets the earner rate model contract address.
    function getEarnerRateModel(address registrar_) internal view returns (address) {
        return toAddress(_get(registrar_, EARNER_RATE_MODEL));
    }

    /// @notice Gets the mint delay.
    function getMintDelay(address registrar_) internal view returns (uint256) {
        return uint256(_get(registrar_, MINT_DELAY));
    }

    /// @notice Gets the minter freeze time.
    function getMinterFreezeTime(address registrar_) internal view returns (uint256) {
        return uint256(_get(registrar_, MINTER_FREEZE_TIME));
    }

    /// @notice Gets the minter rate model contract address.
    function getMinterRateModel(address registrar_) internal view returns (address) {
        return toAddress(_get(registrar_, MINTER_RATE_MODEL));
    }

    /// @notice Gets the mint TTL.
    function getMintTTL(address registrar_) internal view returns (uint256) {
        return uint256(_get(registrar_, MINT_TTL));
    }

    /// @notice Gets the mint ratio.
    function getMintRatio(address registrar_) internal view returns (uint256) {
        return uint256(_get(registrar_, MINT_RATIO));
    }

    /// @notice Gets the update collateral interval.
    function getUpdateCollateralInterval(address registrar_) internal view returns (uint256) {
        return uint256(_get(registrar_, UPDATE_COLLATERAL_INTERVAL));
    }

    /// @notice Gets the update collateral validator threshold.
    function getUpdateCollateralValidatorThreshold(address registrar_) internal view returns (uint256) {
        return uint256(_get(registrar_, UPDATE_COLLATERAL_VALIDATOR_THRESHOLD));
    }

    /// @notice Checks if the given earner is approved.
    function isApprovedEarner(address registrar_, address earner_) internal view returns (bool) {
        return _contains(registrar_, EARNERS_LIST, earner_);
    }

    /// @notice Checks if the `earners_list_ignored` exists.
    function isEarnersListIgnored(address registrar_) internal view returns (bool) {
        return _get(registrar_, EARNERS_LIST_IGNORED) != bytes32(0);
    }

    /// @notice Checks if the given minter is approved.
    function isApprovedMinter(address registrar_, address minter_) internal view returns (bool) {
        return _contains(registrar_, MINTERS_LIST, minter_);
    }

    /// @notice Checks if the given validator is approved.
    function isApprovedValidator(address registrar_, address validator_) internal view returns (bool) {
        return _contains(registrar_, VALIDATORS_LIST, validator_);
    }

    /// @notice Gets the penalty rate.
    function getPenaltyRate(address registrar_) internal view returns (uint256) {
        return uint256(_get(registrar_, PENALTY_RATE));
    }

    /// @notice Gets the vault contract address.
    function getVault(address registrar_) internal view returns (address) {
        return ITTGRegistrar(registrar_).vault();
    }

    /// @notice Converts given bytes32 to address.
    function toAddress(bytes32 input_) internal pure returns (address) {
        return address(uint160(uint256(input_)));
    }

    /// @notice Checks if the given list contains the given account.
    function _contains(address registrar_, bytes32 listName_, address account_) private view returns (bool) {
        return ITTGRegistrar(registrar_).listContains(listName_, account_);
    }

    /// @notice Gets the value of the given key.
    function _get(address registrar_, bytes32 key_) private view returns (bytes32) {
        return ITTGRegistrar(registrar_).get(key_);
    }
}

// src/interfaces/IMinterGateway.sol

/**
 * @title  Minter Gateway Interface.
 * @author M^0 Labs
 */
interface IMinterGateway is IContinuousIndexing, IERC712 {
    /* ============ Events ============ */

    /**
     * @notice Emitted when M tokens are burned and an inactive minter's owed M balance decreased.
     * @param  minter The address of the minter.
     * @param  amount The amount of M tokens burned.
     * @param  payer  The address of the payer.
     */
    event BurnExecuted(address indexed minter, uint240 amount, address indexed payer);

    /**
     * @notice Emitted when M tokens are burned and an active minter's owed M balance decreased.
     * @param  minter          The address of the minter.
     * @param  principalAmount The principal amount of M tokens burned.
     * @param  amount          The amount of M tokens burned.
     * @param  payer           The address of the payer.
     */
    event BurnExecuted(address indexed minter, uint112 principalAmount, uint240 amount, address indexed payer);

    /**
     * @notice Emitted when a minter's collateral is updated.
     * @param  minter                           Address of the minter
     * @param  collateral                       The latest amount of collateral
     * @param  totalResolvedCollateralRetrieval The total collateral amount of outstanding retrievals resolved.
     * @param  metadataHash                     The hash of some metadata reserved for future informational use.
     * @param  timestamp                        The timestamp of the collateral update,
     *                                          minimum of given validators' signatures.
     */
    event CollateralUpdated(
        address indexed minter,
        uint240 collateral,
        uint240 totalResolvedCollateralRetrieval,
        bytes32 indexed metadataHash,
        uint40 timestamp
    );

    /**
     * @notice Emitted when a minter is activated.
     * @param  minter Address of the minter that was activated
     * @param  caller Address who called the function
     */
    event MinterActivated(address indexed minter, address indexed caller);

    /**
     * @notice Emitted when a minter is deactivated.
     * @param  minter        Address of the minter that was deactivated.
     * @param  inactiveOwedM Amount of M tokens owed by the minter (in an inactive state).
     * @param  caller        Address who called the function.
     */
    event MinterDeactivated(address indexed minter, uint240 inactiveOwedM, address indexed caller);

    /**
     * @notice Emitted when a minter is frozen.
     * @param  minter      Address of the minter that was frozen
     * @param  frozenUntil Timestamp until the minter is frozen
     */
    event MinterFrozen(address indexed minter, uint40 frozenUntil);

    /**
     * @notice Emitted when a mint proposal is canceled.
     * @param  mintId    The id of the canceled mint proposal.
     * @param  minter    The address of the minter for which the mint was canceled.
     * @param  canceller The address of the validator who canceled the mint proposal.
     */
    event MintCanceled(uint48 indexed mintId, address indexed minter, address indexed canceller);

    /**
     * @notice Emitted when a mint proposal is executed.
     * @param  mintId          The id of the executed mint proposal.
     * @param  minter          The address of the minter that executed the mint.
     * @param  principalAmount The principal amount of M tokens minted.
     * @param  amount          The amount of M tokens minted.
     */
    event MintExecuted(uint48 indexed mintId, address indexed minter, uint112 principalAmount, uint240 amount);

    /**
     * @notice Emitted when a mint proposal is created.
     * @param  mintId      The id of mint proposal.
     * @param  minter      The address of the minter that proposed the mint.
     * @param  amount      The amount of M tokens to mint.
     * @param  destination The address to mint to.
     */
    event MintProposed(uint48 indexed mintId, address indexed minter, uint240 amount, address indexed destination);

    /**
     * @notice Emitted when a penalty is imposed on `minter` for missed update collateral intervals.
     * @param  minter          The address of the minter.
     * @param  missedIntervals The number of update intervals missed.
     * @param  penaltyAmount   The present amount of penalty charge.
     */
    event MissedIntervalsPenaltyImposed(address indexed minter, uint40 missedIntervals, uint240 penaltyAmount);

    /**
     * @notice Emitted when a penalty is imposed on `minter` for undercollateralization.
     * @param  minter        The address of the minter.
     * @param  excessOwedM   The present amount of owed M in excess of allowed owed M.
     * @param  timeSpan      The span of time over which the undercollateralization penalty was applied.
     * @param  penaltyAmount The present amount of penalty charge.
     */
    event UndercollateralizedPenaltyImposed(
        address indexed minter,
        uint240 excessOwedM,
        uint40 timeSpan,
        uint240 penaltyAmount
    );

    /**
     * @notice Emitted when a collateral retrieval proposal is created.
     * @param  retrievalId The id of retrieval proposal.
     * @param  minter      The address of the minter.
     * @param  amount      The amount of collateral to retrieve.
     */
    event RetrievalCreated(uint48 indexed retrievalId, address indexed minter, uint240 amount);

    /**
     * @notice Emitted when a collateral retrieval proposal is resolved.
     * @param  retrievalId The id of retrieval proposal.
     * @param  minter      The address of the minter.
     */
    event RetrievalResolved(uint48 indexed retrievalId, address indexed minter);

    /* ============ Custom Errors ============ */

    /// @notice Emitted when calling `activateMinter` with a minter who was previously deactivated.
    error DeactivatedMinter();

    /// @notice Emitted when repay will burn more M than the repay specified.
    error ExceedsMaxRepayAmount(uint240 amount, uint240 maxAmount);

    /// @notice Emitted when calling `mintM` with a proposal that was created more than `mintDelay + mintTTL` time ago.
    error ExpiredMintProposal(uint40 deadline);

    /// @notice Emitted when calling `mintM` or `proposeMint` by a minter who was frozen by validator.
    error FrozenMinter();

    /// @notice Emitted when calling `updateCollateral` with any validator timestamp in the future.
    error FutureTimestamp();

    /// @notice Emitted when calling a function only allowed for active minters.
    error InactiveMinter();

    /// @notice Emitted when calling `cancelMint` or `mintM` with invalid `mintId`.
    error InvalidMintProposal();

    /// @notice Emitted when calling `updateCollateral` if `validators` addresses are not ordered in ascending order.
    error InvalidSignatureOrder();

    /// @notice Emitted when calling `activateMinter` if minter was not approved by TTG.
    error NotApprovedMinter();

    /// @notice Emitted when calling `cancelMint` or `freezeMinter` if `validator` was not approved by TTG.
    error NotApprovedValidator(address validator);

    /// @notice Emitted when calling `updateCollateral` if `validatorThreshold` of signatures was not reached.
    error NotEnoughValidSignatures(uint256 validSignatures, uint256 requiredThreshold);

    /// @notice Emitted when principal of total owed M (active and inactive) will overflow a `type(uint112).max`.
    error OverflowsPrincipalOfTotalOwedM();

    /// @notice Emitted when calling `mintM` if `mintDelay` time has not passed yet.
    error PendingMintProposal(uint40 activeTimestamp);

    /// @notice Emitted when calling `proposeRetrieval` if sum of all outstanding retrievals
    ///         Plus new proposed retrieval amount is greater than collateral.
    error RetrievalsExceedCollateral(uint240 totalPendingRetrievals, uint240 collateral);

    /// @notice Emitted when calling `updateCollateral`
    ///         If `validators`, `signatures`, `timestamps` lengths do not match.
    error SignatureArrayLengthsMismatch();

    /// @notice Emitted when updating collateral with a timestamp earlier than allowed.
    error StaleCollateralUpdate(uint40 newTimestamp, uint40 earliestAllowedTimestamp);

    /// @notice Emitted when calling `updateCollateral` with any validator timestamp older than the last signature
    ///         timestamp for that minter and validator.
    error OutdatedValidatorTimestamp(address validator, uint256 timestamp, uint256 lastSignatureTimestamp);

    /// @notice Emitted when calling `deactivateMinter` with a minter still approved in TTG Registrar.
    error StillApprovedMinter();

    /**
     * @notice Emitted when calling `proposeMint`, `mintM`, `proposeRetrieval`
     *         If minter position becomes undercollateralized.
     * @dev    `activeOwedM` is a `uint256` because it may represent some resulting owed M from computations.
     */
    error Undercollateralized(uint256 activeOwedM, uint256 maxAllowedOwedM);

    /// @notice Emitted when calling `burnM` if amount is 0.
    error ZeroBurnAmount();

    /// @notice Emitted in constructor if M Token is 0x0.
    error ZeroMToken();

    /// @notice Emitted when calling `proposeMint` if amount is 0.
    error ZeroMintAmount();

    /// @notice Emitted when calling `proposeMint` if destination is 0x0.
    error ZeroMintDestination();

    /// @notice Emitted when calling `proposeRetrieval` if collateral is 0.
    error ZeroRetrievalAmount();

    /// @notice Emitted in constructor if TTG Registrar is 0x0.
    error ZeroTTGRegistrar();

    /// @notice Emitted in constructor if TTG Distribution Vault is set to 0x0 in TTG Registrar.
    error ZeroTTGVault();

    /// @notice Emitted when calling `updateCollateral` with any validator timestamp of 0.
    error ZeroTimestamp();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Updates collateral for minters
     * @param  collateral   The amount of collateral
     * @param  retrievalIds The list of active proposeRetrieval requests to close
     * @param  metadataHash The hash of metadata of the collateral update, reserved for future informational use
     * @param  validators   The list of validators
     * @param  timestamps   The list of timestamps of validators' signatures
     * @param  signatures   The list of signatures
     * @return minTimestamp The minimum timestamp of all validators' signatures
     */
    function updateCollateral(
        uint256 collateral,
        uint256[] calldata retrievalIds,
        bytes32 metadataHash,
        address[] calldata validators,
        uint256[] calldata timestamps,
        bytes[] calldata signatures
    ) external returns (uint40 minTimestamp);

    /**
     * @notice Proposes retrieval of minter's off-chain collateral
     * @param  collateral  The amount of collateral to retrieve
     * @return retrievalId The unique id of created retrieval proposal
     */
    function proposeRetrieval(uint256 collateral) external returns (uint48 retrievalId);

    /**
     * @notice Proposes minting of M tokens
     * @param  amount      The amount of M tokens to mint
     * @param  destination The address to mint to
     * @return mintId      The unique id of created mint proposal
     */
    function proposeMint(uint256 amount, address destination) external returns (uint48 mintId);

    /**
     * @notice Executes minting of M tokens
     * @param  mintId          The id of outstanding mint proposal for minter
     * @return principalAmount The amount of principal of owed M minted.
     * @return amount          The amount of M tokens minted.
     */
    function mintM(uint256 mintId) external returns (uint112 principalAmount, uint240 amount);

    /**
     * @notice Burns M tokens
     * @dev    If amount to burn is greater than minter's owedM including penalties, burn all up to owedM.
     * @param  minter          The address of the minter to burn M tokens for.
     * @param  maxAmount       The max amount of M tokens to burn.
     * @return principalAmount The amount of principal of owed M burned.
     * @return amount          The amount of M tokens burned.
     */
    function burnM(address minter, uint256 maxAmount) external returns (uint112 principalAmount, uint240 amount);

    /**
     * @notice Burns M tokens
     * @dev    If amount to burn is greater than minter's owedM including penalties, burn all up to owedM.
     * @param  minter             The address of the minter to burn M tokens for.
     * @param  maxPrincipalAmount The max amount of principal of owed M to burn.
     * @param  maxAmount          The max amount of M tokens to burn.
     * @return principalAmount    The amount of principal of owed M burned.
     * @return amount             The amount of M tokens burned.
     */
    function burnM(
        address minter,
        uint256 maxPrincipalAmount,
        uint256 maxAmount
    ) external returns (uint112 principalAmount, uint240 amount);

    /**
     * @notice Cancels minting request for selected minter by validator
     * @param  minter The address of the minter to cancelMint minting request for
     * @param  mintId The id of outstanding mint request
     */
    function cancelMint(address minter, uint256 mintId) external;

    /**
     * @notice Freezes minter
     * @param  minter      The address of the minter to freeze
     * @return frozenUntil The timestamp until which minter is frozen
     */
    function freezeMinter(address minter) external returns (uint40 frozenUntil);

    /**
     * @notice Activate an approved minter.
     * @dev    MUST revert if `minter` is not recorded as an approved minter in TTG Registrar.
     * @dev    MUST revert if `minter` has been deactivated.
     * @param  minter The address of the minter to activate
     */
    function activateMinter(address minter) external;

    /**
     * @notice Deactivates an active minter.
     * @dev    MUST revert if the minter is still approved.
     * @dev    MUST revert if the minter is not active.
     * @param  minter        The address of the minter to deactivate.
     * @return inactiveOwedM The inactive owed M for the deactivated minter.
     */
    function deactivateMinter(address minter) external returns (uint240 inactiveOwedM);

    /* ============ View/Pure Functions ============ */

    /// @notice The address of M token
    function mToken() external view returns (address);

    /// @notice The address of TTG Registrar contract.
    function ttgRegistrar() external view returns (address);

    /// @notice The address of TTG Vault contract.
    function ttgVault() external view returns (address);

    /// @notice The last saved value of Minter rate.
    function minterRate() external view returns (uint32);

    /// @notice The principal of total owed M for all active minters.
    function principalOfTotalActiveOwedM() external view returns (uint112);

    /// @notice The total owed M for all active minters.
    function totalActiveOwedM() external view returns (uint240);

    /// @notice The total owed M for all inactive minters.
    function totalInactiveOwedM() external view returns (uint240);

    /// @notice The total owed M for all minters.
    function totalOwedM() external view returns (uint240);

    /// @notice The difference between total owed M and M token total supply.
    function excessOwedM() external view returns (uint240);

    /// @notice The principal of active owed M of minter.
    function principalOfActiveOwedMOf(address minter_) external view returns (uint112);

    /// @notice The active owed M of minter.
    function activeOwedMOf(address minter) external view returns (uint240);

    /**
     * @notice The max allowed active owed M of minter taking into account collateral amount and retrieval proposals.
     * @dev    This is the only present value that requires a `uint256` since it is the result of a multiplication
     *         between a `uint240` and a value that has a max of `65,000` (the mint ratio).
     */
    function maxAllowedActiveOwedMOf(address minter) external view returns (uint256);

    /// @notice The inactive owed M of deactivated minter.
    function inactiveOwedMOf(address minter) external view returns (uint240);

    /// @notice The collateral of a given minter.
    function collateralOf(address minter) external view returns (uint240);

    /// @notice The timestamp of the last collateral update of minter.
    function collateralUpdateTimestampOf(address minter) external view returns (uint40);

    /// @notice The timestamp after which an additional penalty for a missed update interval will be charged.
    function collateralPenaltyDeadlineOf(address minter) external view returns (uint40);

    /// @notice The timestamp after which the minter's collateral is assumed to be 0 due to a missed update.
    function collateralExpiryTimestampOf(address minter) external view returns (uint40);

    /// @notice The timestamp until which minter is already penalized for missed collateral updates.
    function penalizedUntilOf(address minter) external view returns (uint40);

    /// @notice The timestamp when `minter` created their latest retrieval proposal.
    function latestProposedRetrievalTimestampOf(address minter) external view returns (uint40);

    /**
     * @notice Returns the last signature timestamp used by `validator` to update collateral for `minter`.
     * @param  minter    The address of the minter.
     * @param  validator The address of the validator.
     * @return The last signature timestamp used.
     */
    function getLastSignatureTimestamp(address minter, address validator) external view returns (uint256);

    /**
     * @notice Returns the EIP-712 digest for updateCollateral method.
     * @param  minter       The address of the minter.
     * @param  collateral   The amount of collateral.
     * @param  retrievalIds The list of outstanding collateral retrieval IDs to resolve.
     * @param  metadataHash The hash of metadata of the collateral update, reserved for future informational use.
     * @param  timestamp    The timestamp of the collateral update.
     */
    function getUpdateCollateralDigest(
        address minter,
        uint256 collateral,
        uint256[] calldata retrievalIds,
        bytes32 metadataHash,
        uint256 timestamp
    ) external view returns (bytes32);

    /// @notice The mint proposal of minters, only 1 active proposal per minter
    function mintProposalOf(
        address minter
    ) external view returns (uint48 mintId, uint40 createdAt, address destination, uint240 amount);

    /// @notice The amount of a pending retrieval request for an active minter.
    function pendingCollateralRetrievalOf(address minter, uint256 retrievalId) external view returns (uint240);

    /// @notice The total amount of pending retrieval requests for an active minter.
    function totalPendingCollateralRetrievalOf(address minter) external view returns (uint240);

    /// @notice The timestamp when minter becomes unfrozen after being frozen by validator.
    function frozenUntilOf(address minter) external view returns (uint40);

    /// @notice Checks if minter was activated after approval by TTG
    function isActiveMinter(address minter) external view returns (bool);

    /// @notice Checks if minter was deactivated after removal by TTG
    function isDeactivatedMinter(address minter) external view returns (bool);

    /// @notice Checks if minter was frozen by validator
    function isFrozenMinter(address minter) external view returns (bool);

    /// @notice Checks if minter was approved by TTG
    function isMinterApproved(address minter) external view returns (bool);

    /// @notice Checks if validator was approved by TTG
    function isValidatorApproved(address validator) external view returns (bool);

    /// @notice The delay between mint proposal creation and its earliest execution.
    function mintDelay() external view returns (uint32);

    /// @notice The time while mint request can still be processed before it is considered expired.
    function mintTTL() external view returns (uint32);

    /// @notice The freeze time for minter.
    function minterFreezeTime() external view returns (uint32);

    /// @notice The allowed activeOwedM to collateral ratio.
    function mintRatio() external view returns (uint32);

    /// @notice The % that defines penalty amount for missed collateral updates or excessive owedM value
    function penaltyRate() external view returns (uint32);

    /// @notice The smart contract that defines the minter rate.
    function rateModel() external view returns (address);

    /// @notice The interval that defines the required frequency of collateral updates.
    function updateCollateralInterval() external view returns (uint32);

    /// @notice The number of signatures required for successful collateral update.
    function updateCollateralValidatorThreshold() external view returns (uint256);

    /// @notice Descaler for variables in basis points. Effectively, 100% in basis points.
    function ONE() external pure returns (uint16);

    /// @notice Mint ratio cap. 650% in basis points.
    function MAX_MINT_RATIO() external pure returns (uint32);

    /// @notice Update collateral interval lower cap in seconds.
    function MIN_UPDATE_COLLATERAL_INTERVAL() external pure returns (uint32);

    /// @notice The EIP-712 typehash for the `updateCollateral` method.
    function UPDATE_COLLATERAL_TYPEHASH() external pure returns (bytes32);
}

// lib/common/src/interfaces/IStatefulERC712.sol

/**
 * @title  Stateful Extension for EIP-712 typed structured data hashing and signing with nonces.
 * @author M^0 Labs
 */
interface IStatefulERC712 is IERC712Extended {
    /* ============ Custom Errors ============ */

    /**
     * @notice Revert message when a signing account's nonce is not the expected current nonce.
     * @param  nonce         The nonce used in the signature.
     * @param  expectedNonce The expected nonce to be used in a signature by the signing account.
     */
    error InvalidAccountNonce(uint256 nonce, uint256 expectedNonce);

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns the next nonce to be used in a signature by `account`.
     * @param  account The address of some account.
     * @return nonce   The next nonce to be used in a signature by `account`.
     */
    function nonces(address account) external view returns (uint256 nonce);
}

// src/abstract/ContinuousIndexing.sol

/**
 * @title Abstract Continuous Indexing Contract to handle rate/index updates in inheriting contracts.
 * @author M^0 Labs
 */
abstract contract ContinuousIndexing is IContinuousIndexing {
    /* ============ Variables ============ */

    /// @inheritdoc IContinuousIndexing
    uint128 public latestIndex;

    /// @dev The latest updated rate.
    uint32 internal _latestRate;

    /// @inheritdoc IContinuousIndexing
    uint40 public latestUpdateTimestamp;

    /* ============ Constructor ============ */

    /// @notice Constructs the ContinuousIndexing contract.
    constructor() {
        latestIndex = ContinuousIndexingMath.EXP_SCALED_ONE;
        latestUpdateTimestamp = uint40(block.timestamp);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IContinuousIndexing
    function updateIndex() public virtual returns (uint128 currentIndex_) {
        // NOTE: `_rate()` can depend indirectly on `latestIndex` and `latestUpdateTimestamp`, if the RateModel
        //       depends on earning balances/supply, which depends on `currentIndex()`, so only update them after this.
        uint32 rate_ = _rate();

        if (latestUpdateTimestamp == block.timestamp && _latestRate == rate_) return latestIndex;

        // NOTE: `currentIndex()` depends on `_latestRate`, so only update it after this.
        latestIndex = currentIndex_ = currentIndex();
        _latestRate = rate_;
        latestUpdateTimestamp = uint40(block.timestamp);

        emit IndexUpdated(currentIndex_, rate_);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IContinuousIndexing
    function currentIndex() public view virtual returns (uint128);

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the principal amount (rounded down) given the present amount, using the current index.
     * @param  presentAmount_ The present amount.
     * @return The principal amount rounded down.
     */
    function _getPrincipalAmountRoundedDown(uint240 presentAmount_) internal view returns (uint112) {
        return _getPrincipalAmountRoundedDown(presentAmount_, currentIndex());
    }

    /**
     * @dev    Returns the principal amount (rounded up) given the present amount and an index.
     * @param  presentAmount_ The present amount.
     * @return The principal amount rounded up.
     */
    function _getPrincipalAmountRoundedUp(uint240 presentAmount_) internal view returns (uint112) {
        return _getPrincipalAmountRoundedUp(presentAmount_, currentIndex());
    }

    /**
     * @dev    Returns the present amount (rounded down) given the principal amount and an index.
     * @param  principalAmount_ The principal amount.
     * @param  index_           An index.
     * @return The present amount rounded down.
     */
    function _getPresentAmountRoundedDown(uint112 principalAmount_, uint128 index_) internal pure returns (uint240) {
        return ContinuousIndexingMath.multiplyDown(principalAmount_, index_);
    }

    /**
     * @dev    Returns the present amount (rounded up) given the principal amount and an index.
     * @param  principalAmount_ The principal amount.
     * @param  index_           An index.
     * @return The present amount rounded up.
     */
    function _getPresentAmountRoundedUp(uint112 principalAmount_, uint128 index_) internal pure returns (uint240) {
        return ContinuousIndexingMath.multiplyUp(principalAmount_, index_);
    }

    /**
     * @dev    Returns the principal amount given the present amount, using the current index.
     * @param  presentAmount_ The present amount.
     * @param  index_         An index.
     * @return The principal amount rounded down.
     */
    function _getPrincipalAmountRoundedDown(uint240 presentAmount_, uint128 index_) internal pure returns (uint112) {
        return ContinuousIndexingMath.divideDown(presentAmount_, index_);
    }

    /**
     * @dev    Returns the principal amount given the present amount, using the current index.
     * @param  presentAmount_ The present amount.
     * @param  index_         An index.
     * @return The principal amount rounded up.
     */
    function _getPrincipalAmountRoundedUp(uint240 presentAmount_, uint128 index_) internal pure returns (uint112) {
        return ContinuousIndexingMath.divideUp(presentAmount_, index_);
    }

    /// @dev To be overridden by the inheriting contract to return the current rate.
    function _rate() internal view virtual returns (uint32);
}

// lib/common/src/interfaces/IERC3009.sol

/**
 * @title  Transfer via signed authorization following EIP-3009 standard.
 * @author M^0 Labs
 * @dev    The interface as defined by EIP-3009: https://eips.ethereum.org/EIPS/eip-3009
 */
interface IERC3009 is IStatefulERC712 {
    /* ============ Events ============ */

    /**
     * @notice Emitted when an authorization has been canceled.
     * @param  authorizer Authorizer's address.
     * @param  nonce      Nonce of the canceled authorization.
     */
    event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

    /**
     * @notice Emitted when an authorization has been used.
     * @param  authorizer Authorizer's address.
     * @param  nonce      Nonce of the used authorization.
     */
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    /* ============ Custom Errors ============ */

    /**
     * @notice Emitted when an authorization has already been used.
     * @param  authorizer Authorizer's address.
     * @param  nonce      Nonce of the used authorization.
     */
    error AuthorizationAlreadyUsed(address authorizer, bytes32 nonce);

    /**
     * @notice Emitted when an authorization is expired.
     * @param  timestamp   Timestamp at which the transaction was submitted.
     * @param  validBefore Timestamp before which the authorization would have been valid.
     */
    error AuthorizationExpired(uint256 timestamp, uint256 validBefore);

    /**
     * @notice Emitted when an authorization is not yet valid.
     * @param  timestamp  Timestamp at which the transaction was submitted.
     * @param  validAfter Timestamp after which the authorization will be valid.
     */
    error AuthorizationNotYetValid(uint256 timestamp, uint256 validAfter);

    /**
     * @notice Emitted when the caller of `receiveWithAuthorization` is not the payee.
     * @param  caller Caller's address.
     * @param  payee  Payee's address.
     */
    error CallerMustBePayee(address caller, address payee);

    /* ============ Interactive Functions ============ */

    /**
     * @notice Execute a transfer with a signed authorization.
     * @param  from        Payer's address (Authorizer).
     * @param  to          Payee's address.
     * @param  value       Amount to be transferred.
     * @param  validAfter  The time after which this is valid (unix time).
     * @param  validBefore The time before which this is valid (unix time).
     * @param  nonce       Unique nonce.
     * @param  signature   A byte array ECDSA/secp256k1 signature (encoded r, s, v).
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) external;

    /**
     * @notice Execute a transfer with a signed authorization.
     * @param  from        Payer's address (Authorizer).
     * @param  to          Payee's address.
     * @param  value       Amount to be transferred.
     * @param  validAfter  The time after which this is valid (unix time).
     * @param  validBefore The time before which this is valid (unix time).
     * @param  nonce       Unique nonce.
     * @param  r           An ECDSA/secp256k1 signature parameter.
     * @param  vs          An ECDSA/secp256k1 short signature parameter.
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes32 r,
        bytes32 vs
    ) external;

    /**
     * @notice Execute a transfer with a signed authorization.
     * @param  from        Payer's address (Authorizer).
     * @param  to          Payee's address.
     * @param  value       Amount to be transferred.
     * @param  validAfter  The time after which this is valid (unix time).
     * @param  validBefore The time before which this is valid (unix time).
     * @param  nonce       Unique nonce.
     * @param  v           v of the signature.
     * @param  r           r of the signature.
     * @param  s           s of the signature.
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Receive a transfer with a signed authorization from the payer.
     * @dev    This has an additional check to ensure that the payee's address matches
     *         the caller of this function to prevent front-running attacks.
     *         (See security considerations)
     * @param  from        Payer's address (Authorizer).
     * @param  to          Payee's address.
     * @param  value       Amount to be transferred.
     * @param  validAfter  The time after which this is valid (unix time).
     * @param  validBefore The time before which this is valid (unix time).
     * @param  nonce       Unique nonce.
     * @param  signature   A byte array ECDSA/secp256k1 signature (encoded r, s, v).
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) external;

    /**
     * @notice Receive a transfer with a signed authorization from the payer.
     * @dev    This has an additional check to ensure that the payee's address matches
     *         the caller of this function to prevent front-running attacks.
     *         (See security considerations)
     * @param  from        Payer's address (Authorizer).
     * @param  to          Payee's address.
     * @param  value       Amount to be transferred.
     * @param  validAfter  The time after which this is valid (unix time).
     * @param  validBefore The time before which this is valid (unix time).
     * @param  nonce       Unique nonce.
     * @param  r           An ECDSA/secp256k1 signature parameter.
     * @param  vs          An ECDSA/secp256k1 short signature parameter.
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes32 r,
        bytes32 vs
    ) external;

    /**
     * @notice Receive a transfer with a signed authorization from the payer.
     * @dev    This has an additional check to ensure that the payee's address matches
     *         the caller of this function to prevent front-running attacks.
     *         (See security considerations)
     * @param  from        Payer's address (Authorizer).
     * @param  to          Payee's address.
     * @param  value       Amount to be transferred.
     * @param  validAfter  The time after which this is valid (unix time).
     * @param  validBefore The time before which this is valid (unix time).
     * @param  nonce       Unique nonce.
     * @param  v           v of the signature.
     * @param  r           r of the signature.
     * @param  s           s of the signature.
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Attempt to cancel an authorization.
     * @param  authorizer Authorizer's address.
     * @param  nonce      Nonce of the authorization.
     * @param  signature  A byte array ECDSA/secp256k1 signature (encoded r, s, v).
     */
    function cancelAuthorization(address authorizer, bytes32 nonce, bytes memory signature) external;

    /**
     * @notice Attempt to cancel an authorization.
     * @param  authorizer Authorizer's address.
     * @param  nonce      Nonce of the authorization.
     * @param  r          An ECDSA/secp256k1 signature parameter.
     * @param  vs         An ECDSA/secp256k1 short signature parameter.
     */
    function cancelAuthorization(address authorizer, bytes32 nonce, bytes32 r, bytes32 vs) external;

    /**
     * @notice Attempt to cancel an authorization.
     * @param  authorizer Authorizer's address.
     * @param  nonce      Nonce of the authorization.
     * @param  v          v of the signature.
     * @param  r          r of the signature.
     * @param  s          s of the signature.
     */
    function cancelAuthorization(address authorizer, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns the state of an authorization.
     * @dev    Nonces are randomly generated 32-byte data unique to the authorizer's address
     * @param  authorizer Authorizer's address.
     * @param  nonce      Nonce of the authorization.
     * @return True if the nonce is used.
     */
    function authorizationState(address authorizer, bytes32 nonce) external view returns (bool);

    /// @notice Returns `transferWithAuthorization` typehash.
    function TRANSFER_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);

    /// @notice Returns `receiveWithAuthorization` typehash.
    function RECEIVE_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);

    /// @notice Returns `cancelAuthorization` typehash.
    function CANCEL_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
}

// lib/common/src/ERC712Extended.sol

/**
 * @title  Typed structured data hashing and signing via EIP-712, extended by EIP-5267.
 * @author M^0 Labs
 * @dev    An abstract implementation to satisfy EIP-712: https://eips.ethereum.org/EIPS/eip-712
 */
abstract contract ERC712Extended is IERC712Extended {
    /* ============ Variables ============ */

    /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant _EIP712_DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev keccak256("1")
    bytes32 internal constant _EIP712_VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @dev Initial Chain ID set at deployment.
    uint256 internal immutable _INITIAL_CHAIN_ID;

    /// @dev Initial EIP-712 domain separator set at deployment.
    bytes32 internal immutable _INITIAL_DOMAIN_SEPARATOR;

    /// @dev The name of the contract (stored as a bytes32 instead of a string in order to be immutable).
    bytes32 internal immutable _name;

    /* ============ Constructor ============ */

    /**
     * @notice Constructs the EIP-712 domain separator.
     * @param  name_ The name of the contract.
     */
    constructor(string memory name_) {
        _name = Bytes32String.toBytes32(name_);

        _INITIAL_CHAIN_ID = block.chainid;
        _INITIAL_DOMAIN_SEPARATOR = _getDomainSeparator();
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC712Extended
    function eip712Domain()
        external
        view
        virtual
        returns (
            bytes1 fields_,
            string memory name_,
            string memory version_,
            uint256 chainId_,
            address verifyingContract_,
            bytes32 salt_,
            uint256[] memory extensions_
        )
    {
        return (
            hex"0f", // 01111
            Bytes32String.toString(_name),
            "1",
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /// @inheritdoc IERC712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == _INITIAL_CHAIN_ID ? _INITIAL_DOMAIN_SEPARATOR : _getDomainSeparator();
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Computes the EIP-712 domain separator.
     * @return The EIP-712 domain separator.
     */
    function _getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP712_DOMAIN_HASH,
                    keccak256(bytes(Bytes32String.toString(_name))),
                    _EIP712_VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev    Returns the digest to be signed, via EIP-712, given an internal digest (i.e. hash struct).
     * @param  internalDigest_ The internal digest.
     * @return The digest to be signed.
     */
    function _getDigest(bytes32 internalDigest_) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), internalDigest_));
    }

    /**
     * @dev   Revert if the signature is expired.
     * @param expiry_ Timestamp at which the signature expires or max uint256 for no expiry.
     */
    function _revertIfExpired(uint256 expiry_) internal view {
        if (block.timestamp > expiry_) revert SignatureExpired(expiry_, block.timestamp);
    }

    /**
     * @dev   Revert if the signature is invalid.
     * @dev   We first validate if the signature is a valid ECDSA signature and return early if it is the case.
     *        Then, we validate if it is a valid ERC-1271 signature, and return early if it is the case.
     *        If not, we revert with the error from the ECDSA signature validation.
     * @param signer_    The signer of the signature.
     * @param digest_    The digest that was signed.
     * @param signature_ The signature.
     */
    function _revertIfInvalidSignature(address signer_, bytes32 digest_, bytes memory signature_) internal view {
        SignatureChecker.Error error_ = SignatureChecker.validateECDSASignature(signer_, digest_, signature_);

        if (error_ == SignatureChecker.Error.NoError) return;

        if (SignatureChecker.isValidERC1271Signature(signer_, digest_, signature_)) return;

        _revertIfError(error_);
    }

    /**
     * @dev    Returns the signer of a signed digest, via EIP-712, and reverts if the signature is invalid.
     * @param  digest_ The digest that was signed.
     * @param  v_      v of the signature.
     * @param  r_      r of the signature.
     * @param  s_      s of the signature.
     * @return signer_ The signer of the digest.
     */
    function _getSignerAndRevertIfInvalidSignature(
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal pure returns (address signer_) {
        SignatureChecker.Error error_;

        (error_, signer_) = SignatureChecker.recoverECDSASigner(digest_, v_, r_, s_);

        _revertIfError(error_);
    }

    /**
     * @dev   Revert if the signature is invalid.
     * @param signer_ The signer of the signature.
     * @param digest_ The digest that was signed.
     * @param r_      An ECDSA/secp256k1 signature parameter.
     * @param vs_     An ECDSA/secp256k1 short signature parameter.
     */
    function _revertIfInvalidSignature(address signer_, bytes32 digest_, bytes32 r_, bytes32 vs_) internal pure {
        _revertIfError(SignatureChecker.validateECDSASignature(signer_, digest_, r_, vs_));
    }

    /**
     * @dev   Revert if the signature is invalid.
     * @param signer_ The signer of the signature.
     * @param digest_ The digest that was signed.
     * @param v_      v of the signature.
     * @param r_      r of the signature.
     * @param s_      s of the signature.
     */
    function _revertIfInvalidSignature(
        address signer_,
        bytes32 digest_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal pure {
        _revertIfError(SignatureChecker.validateECDSASignature(signer_, digest_, v_, r_, s_));
    }

    /**
     * @dev   Revert if error.
     * @param error_ The SignatureChecker Error enum.
     */
    function _revertIfError(SignatureChecker.Error error_) private pure {
        if (error_ == SignatureChecker.Error.NoError) return;
        if (error_ == SignatureChecker.Error.InvalidSignature) revert InvalidSignature();
        if (error_ == SignatureChecker.Error.InvalidSignatureLength) revert InvalidSignatureLength();
        if (error_ == SignatureChecker.Error.InvalidSignatureS) revert InvalidSignatureS();
        if (error_ == SignatureChecker.Error.InvalidSignatureV) revert InvalidSignatureV();
        if (error_ == SignatureChecker.Error.SignerMismatch) revert SignerMismatch();

        revert InvalidSignature();
    }
}

// lib/common/src/interfaces/IERC20Extended.sol

/**
 * @title  An ERC20 token extended with EIP-2612 permits for signed approvals (via EIP-712
 *         and with EIP-1271 compatibility), and extended with EIP-3009 transfer with authorization (via EIP-712).
 * @author M^0 Labs
 * @dev    The additional interface as defined by EIP-2612: https://eips.ethereum.org/EIPS/eip-2612
 */
interface IERC20Extended is IERC20, IERC3009 {
    /* ============ Custom Errors ============ */

    /**
     * @notice Revert message when spender's allowance is not sufficient.
     * @param  spender    Address that may be allowed to operate on tokens without being their owner.
     * @param  allowance  Amount of tokens a `spender` is allowed to operate with.
     * @param  needed     Minimum amount required to perform a transfer.
     */
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @notice Revert message emitted when the transferred amount is insufficient.
     * @param  amount Amount transferred.
     */
    error InsufficientAmount(uint256 amount);

    /**
     * @notice Revert message emitted when the recipient of a token is invalid.
     * @param  recipient Address of the invalid recipient.
     */
    error InvalidRecipient(address recipient);

    /* ============ Interactive Functions ============ */

    /**
     * @notice Approves `spender` to spend up to `amount` of the token balance of `owner`, via a signature.
     * @param  owner    The address of the account who's token balance is being approved to be spent by `spender`.
     * @param  spender  The address of an account allowed to spend on behalf of `owner`.
     * @param  value    The amount of the allowance being approved.
     * @param  deadline The last timestamp where the signature is still valid.
     * @param  v        An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  r        An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     * @param  s        An ECDSA secp256k1 signature parameter (EIP-2612 via EIP-712).
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Approves `spender` to spend up to `amount` of the token balance of `owner`, via a signature.
     * @param  owner     The address of the account who's token balance is being approved to be spent by `spender`.
     * @param  spender   The address of an account allowed to spend on behalf of `owner`.
     * @param  value     The amount of the allowance being approved.
     * @param  deadline  The last timestamp where the signature is still valid.
     * @param  signature An arbitrary signature (EIP-712).
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, bytes memory signature) external;

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the EIP712 typehash used in the encoding of the digest for the permit function.
    function PERMIT_TYPEHASH() external view returns (bytes32);
}

// src/interfaces/IMToken.sol

/**
 * @title  M Token Interface.
 * @author M^0 Labs
 */
interface IMToken is IContinuousIndexing, IERC20Extended {
    /* ============ Events ============ */

    /**
     * @notice Emitted when account starts being an M earner.
     * @param  account The account that started earning.
     */
    event StartedEarning(address indexed account);

    /**
     * @notice Emitted when account stops being an M earner.
     * @param  account The account that stopped earning.
     */
    event StoppedEarning(address indexed account);

    /* ============ Custom Errors ============ */

    /**
     * @notice Emitted when there is insufficient balance to decrement from `account`.
     * @param  account     The account with insufficient balance.
     * @param  rawBalance  The raw balance of the account.
     * @param  amount      The amount to decrement the `rawBalance` by.
     */
    error InsufficientBalance(address account, uint256 rawBalance, uint256 amount);

    /// @notice Emitted when calling `stopEarning` for an account approved as earner by TTG.
    error IsApprovedEarner();

    /// @notice Emitted when calling `startEarning` for an account not approved as earner by TTG.
    error NotApprovedEarner();

    /// @notice Emitted when calling `mint`, `burn` not by Minter Gateway.
    error NotMinterGateway();

    /// @notice Emitted when principal of total supply (earning and non-earning) will overflow a `type(uint112).max`.
    error OverflowsPrincipalOfTotalSupply();

    /// @notice Emitted in constructor if Minter Gateway is 0x0.
    error ZeroMinterGateway();

    /// @notice Emitted in constructor if TTG Registrar is 0x0.
    error ZeroTTGRegistrar();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Mints tokens.
     * @param  account The address of account to mint to.
     * @param  amount  The amount of M Token to mint.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Burns tokens.
     * @param  account The address of account to burn from.
     * @param  amount  The amount of M Token to burn.
     */
    function burn(address account, uint256 amount) external;

    /// @notice Starts earning for caller if allowed by TTG.
    function startEarning() external;

    /// @notice Stops earning for caller.
    function stopEarning() external;

    /**
     * @notice Stops earning for `account`.
     * @dev    MUST revert if `account` is an approved earner in TTG Registrar.
     * @param  account The account to stop earning for.
     */
    function stopEarning(address account) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The address of the Minter Gateway contract.
    function minterGateway() external view returns (address);

    /// @notice The address of the TTG Registrar contract.
    function ttgRegistrar() external view returns (address);

    /// @notice The address of TTG approved earner rate model.
    function rateModel() external view returns (address);

    /// @notice The current value of earner rate in basis points.
    function earnerRate() external view returns (uint32);

    /**
     * @notice The principal of an earner M token balance.
     * @param  account The account to get the principal balance of.
     * @return The principal balance of the account.
     */
    function principalBalanceOf(address account) external view returns (uint240);

    /// @notice The principal of the total earning supply of M Token.
    function principalOfTotalEarningSupply() external view returns (uint112);

    /// @notice The total earning supply of M Token.
    function totalEarningSupply() external view returns (uint240);

    /// @notice The total non-earning supply of M Token.
    function totalNonEarningSupply() external view returns (uint240);

    /**
     * @notice Checks if account is an earner.
     * @param  account The account to check.
     * @return True if account is an earner, false otherwise.
     */
    function isEarning(address account) external view returns (bool);
}

// src/MinterGateway.sol

/*

███╗   ███╗██╗███╗   ██╗████████╗███████╗██████╗      ██████╗  █████╗ ████████╗███████╗██╗    ██╗ █████╗ ██╗   ██╗
████╗ ████║██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗    ██╔════╝ ██╔══██╗╚══██╔══╝██╔════╝██║    ██║██╔══██╗╚██╗ ██╔╝
██╔████╔██║██║██╔██╗ ██║   ██║   █████╗  ██████╔╝    ██║  ███╗███████║   ██║   █████╗  ██║ █╗ ██║███████║ ╚████╔╝
██║╚██╔╝██║██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗    ██║   ██║██╔══██║   ██║   ██╔══╝  ██║███╗██║██╔══██║  ╚██╔╝
██║ ╚═╝ ██║██║██║ ╚████║   ██║   ███████╗██║  ██║    ╚██████╔╝██║  ██║   ██║   ███████╗╚███╔███╔╝██║  ██║   ██║
╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝

-->> Where money is born. <<--

*/

/**
 * @title  MinterGateway
 * @author M^0 Labs
 * @notice Minting Gateway of M Token for all approved by TTG and activated minters.
 */
contract MinterGateway is IMinterGateway, ContinuousIndexing, ERC712Extended {
    /* ============ Structs ============ */

    /**
     * @notice Mint proposal struct.
     * @param  id          The unique ID of the mint proposal.
     * @param  createdAt   The timestamp at which the mint proposal was created.
     * @param  destination The address to mint M to.
     * @param  amount      The amount of M to mint.
     */
    struct MintProposal {
        // 1st slot
        uint48 id;
        uint40 createdAt;
        address destination;
        // 2nd slot
        uint240 amount;
    }

    /**
     * @notice Minter state struct.
     * @param  isActive                Whether the minter is active or not.
     * @param  isDeactivated           Whether the minter is deactivated or not.
     * @param  collateral              The amount of collateral the minter has.
     * @param  totalPendingRetrievals  The total amount of pending retrievals.
     * @param  updateTimestamp         The timestamp at which the minter last updated their collateral.
     * @param  penalizedUntilTimestamp The timestamp until which the minter is penalized.
     * @param  frozenUntilTimestamp    The timestamp until which the minter is frozen.
     * @param  latestProposedRetrievalTimestamp The timestamp at which the minter last proposed a retrieval.
     */
    struct MinterState {
        // 1st slot
        bool isActive;
        bool isDeactivated;
        uint240 collateral;
        // 2nd slot
        uint240 totalPendingRetrievals;
        // 3rd slot
        uint40 updateTimestamp;
        uint40 penalizedUntilTimestamp;
        uint40 frozenUntilTimestamp;
        uint40 latestProposedRetrievalTimestamp;
    }

    /* ============ Variables ============ */

    /// @inheritdoc IMinterGateway
    uint16 public constant ONE = 10_000;

    /// @inheritdoc IMinterGateway
    uint32 public constant MAX_MINT_RATIO = 65_000;

    /// @notice IMinterGateway
    uint32 public constant MIN_UPDATE_COLLATERAL_INTERVAL = 3_600;

    // solhint-disable-next-line max-line-length
    /// @dev keccak256("UpdateCollateral(address minter,uint256 collateral,uint256[] retrievalIds,bytes32 metadataHash,uint256 timestamp)")
    /// @inheritdoc IMinterGateway
    bytes32 public constant UPDATE_COLLATERAL_TYPEHASH =
        0x22b57ca54bd15c6234b29e87aa1d76a0841b6e65e63d7acacef989de0bc3ff9e;

    /// @inheritdoc IMinterGateway
    address public immutable ttgRegistrar;

    /// @inheritdoc IMinterGateway
    address public immutable ttgVault;

    /// @inheritdoc IMinterGateway
    address public immutable mToken;

    /// @inheritdoc IMinterGateway
    uint240 public totalInactiveOwedM;

    /// @inheritdoc IMinterGateway
    uint112 public principalOfTotalActiveOwedM;

    /// @dev Nonce used to generate unique mint proposal IDs.
    uint48 internal _mintNonce;

    /// @dev Nonce used to generate unique retrieval proposal IDs.
    uint48 internal _retrievalNonce;

    /// @dev The state of each minter, their collaterals, relevant timestamps, and total pending retrievals.
    mapping(address minter => MinterState state) internal _minterStates;

    /// @dev The mint proposals of minter (mint ID, creation timestamp, destination, amount).
    mapping(address minter => MintProposal proposal) internal _mintProposals;

    /// @dev The owed M of active and inactive minters (principal of active, inactive).
    mapping(address minter => uint240 rawOwedM) internal _rawOwedM;

    /// @dev The pending collateral retrievals of minter (retrieval ID, amount).
    mapping(address minter => mapping(uint48 retrievalId => uint240 amount)) internal _pendingCollateralRetrievals;

    /// @dev The last update signature timestamp of each validator for each minter.
    mapping(address minter => mapping(address validator => uint256 timestamp)) internal _lastSignatureTimestamp;

    /* ============ Modifiers ============ */

    /**
     * @notice Only allow active minter to call function.
     * @param  minter_ The address of the minter to check.
     */
    modifier onlyActiveMinter(address minter_) {
        _revertIfInactiveMinter(minter_);

        _;
    }

    /// @notice Only allow approved validator in TTG to call function.
    modifier onlyApprovedValidator() {
        _revertIfNotApprovedValidator(msg.sender);

        _;
    }

    /// @notice Only allow unfrozen minter to call function.
    modifier onlyUnfrozenMinter() {
        _revertIfFrozenMinter(msg.sender);

        _;
    }

    /* ============ Constructor ============ */

    /**
     * @notice Constructor.
     * @param  ttgRegistrar_ The address of the TTG Registrar contract.
     * @param  mToken_        The address of the M Token.
     */
    constructor(address ttgRegistrar_, address mToken_) ContinuousIndexing() ERC712Extended("MinterGateway") {
        if ((ttgRegistrar = ttgRegistrar_) == address(0)) revert ZeroTTGRegistrar();
        if ((ttgVault = TTGRegistrarReader.getVault(ttgRegistrar_)) == address(0)) revert ZeroTTGVault();
        if ((mToken = mToken_) == address(0)) revert ZeroMToken();
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMinterGateway
    function updateCollateral(
        uint256 collateral_,
        uint256[] calldata retrievalIds_,
        bytes32 metadataHash_,
        address[] calldata validators_,
        uint256[] calldata timestamps_,
        bytes[] calldata signatures_
    ) external onlyActiveMinter(msg.sender) returns (uint40 minTimestamp_) {
        if (validators_.length != signatures_.length || signatures_.length != timestamps_.length) {
            revert SignatureArrayLengthsMismatch();
        }

        // Verify that enough valid signatures are provided, and get the minimum timestamp across all valid signatures.
        minTimestamp_ = _verifyValidatorSignatures(
            msg.sender,
            collateral_,
            retrievalIds_,
            metadataHash_,
            validators_,
            timestamps_,
            signatures_
        );

        _imposePenaltyIfMissedCollateralUpdates(msg.sender);

        _imposePenaltyIfUndercollateralized(msg.sender, minTimestamp_);

        uint240 safeCollateral_ = UIntMath.safe240(collateral_);
        uint240 totalResolvedCollateralRetrieval_ = _resolvePendingRetrievals(msg.sender, retrievalIds_);

        emit CollateralUpdated(
            msg.sender,
            safeCollateral_,
            totalResolvedCollateralRetrieval_,
            metadataHash_,
            minTimestamp_
        );

        _updateCollateral(msg.sender, safeCollateral_, minTimestamp_);

        // NOTE: Above functionality already has access to `currentIndex()`, and since the completion of the collateral
        //       update can result in a new rate, we should update the index here to lock in that rate.
        updateIndex();
    }

    /// @inheritdoc IMinterGateway
    function proposeRetrieval(uint256 collateral_) external onlyActiveMinter(msg.sender) returns (uint48 retrievalId_) {
        if (collateral_ == 0) revert ZeroRetrievalAmount();

        unchecked {
            retrievalId_ = ++_retrievalNonce;
        }

        MinterState storage minterState_ = _minterStates[msg.sender];
        uint240 currentCollateral_ = minterState_.collateral;
        uint240 safeCollateral_ = UIntMath.safe240(collateral_);
        uint240 updatedTotalPendingRetrievals_ = minterState_.totalPendingRetrievals + safeCollateral_;

        // NOTE: Revert if collateral is less than sum of all pending retrievals even if there is no owed M by minter.
        if (currentCollateral_ < updatedTotalPendingRetrievals_) {
            revert RetrievalsExceedCollateral(updatedTotalPendingRetrievals_, currentCollateral_);
        }

        minterState_.latestProposedRetrievalTimestamp = uint40(block.timestamp);
        minterState_.totalPendingRetrievals = updatedTotalPendingRetrievals_;
        _pendingCollateralRetrievals[msg.sender][retrievalId_] = safeCollateral_;

        _revertIfUndercollateralized(msg.sender, 0);

        emit RetrievalCreated(retrievalId_, msg.sender, safeCollateral_);
    }

    /// @inheritdoc IMinterGateway
    function proposeMint(
        uint256 amount_,
        address destination_
    ) external onlyActiveMinter(msg.sender) onlyUnfrozenMinter returns (uint48 mintId_) {
        if (amount_ == 0) revert ZeroMintAmount();
        if (destination_ == address(0)) revert ZeroMintDestination();

        uint240 safeAmount_ = UIntMath.safe240(amount_);

        //NOTE: remove by fuzzer, not checking collateral on this stage
        _revertIfUndercollateralized(msg.sender, safeAmount_); // Ensure minter remains sufficiently collateralized.

        unchecked {
            mintId_ = ++_mintNonce;
        }

        _mintProposals[msg.sender] = MintProposal(mintId_, uint40(block.timestamp), destination_, safeAmount_);

        emit MintProposed(mintId_, msg.sender, safeAmount_, destination_);
    }

    /// @inheritdoc IMinterGateway
    function mintM(
        uint256 mintId_
    ) external onlyActiveMinter(msg.sender) onlyUnfrozenMinter returns (uint112 principalAmount_, uint240 amount_) {
        MintProposal storage mintProposal_ = _mintProposals[msg.sender];

        uint48 id_;
        uint40 createdAt_;
        address destination_;
        (id_, createdAt_, destination_, amount_) = (
            mintProposal_.id,
            mintProposal_.createdAt,
            mintProposal_.destination,
            mintProposal_.amount
        );

        if (id_ != mintId_) revert InvalidMintProposal();

        unchecked {
            // Check that mint proposal is executable.
            uint40 activeAt_ = createdAt_ + mintDelay();
            if (block.timestamp < activeAt_) revert PendingMintProposal(activeAt_);

            uint40 expiresAt_ = activeAt_ + mintTTL();
            if (block.timestamp > expiresAt_) revert ExpiredMintProposal(expiresAt_);
        }

        _revertIfUndercollateralized(msg.sender, amount_); // Ensure minter remains sufficiently collateralized.

        delete _mintProposals[msg.sender]; // Delete mint request.

        // Adjust principal of active owed M for minter.
        // NOTE: When minting a present amount, round the principal up in favor of the protocol.
        principalAmount_ = _getPrincipalAmountRoundedUp(amount_);
        uint112 principalOfTotalActiveOwedM_ = principalOfTotalActiveOwedM;

        emit MintExecuted(id_, msg.sender, principalAmount_, amount_);

        unchecked {
            uint256 newPrincipalOfTotalActiveOwedM_ = uint256(principalOfTotalActiveOwedM_) + principalAmount_;

            // As an edge case precaution, prevent a mint that, if all owed M (active and inactive) was converted to
            // a principal active amount, would overflow the `uint112 principalOfTotalActiveOwedM`.
            if (
                // NOTE: Round the principal up for worst case.
                newPrincipalOfTotalActiveOwedM_ + _getPrincipalAmountRoundedUp(totalInactiveOwedM) >= type(uint112).max
            ) {
                revert OverflowsPrincipalOfTotalOwedM();
            }

            principalOfTotalActiveOwedM = uint112(newPrincipalOfTotalActiveOwedM_);
            _rawOwedM[msg.sender] += principalAmount_; // Treat rawOwedM as principal since minter is active.
        }

        IMToken(mToken).mint(destination_, amount_);

        // NOTE: Above functionality already has access to `currentIndex()`, and since the completion of the mint
        //       can result in a new rate, we should update the index here to lock in that rate.
        updateIndex();
    }

    /// @inheritdoc IMinterGateway
    function burnM(address minter_, uint256 maxAmount_) external returns (uint112 principalAmount_, uint240 amount_) {
        (principalAmount_, amount_) = burnM(
            minter_,
            _getPrincipalAmountRoundedDown(UIntMath.safe240(maxAmount_)),
            maxAmount_
        );
    }

    /// @inheritdoc IMinterGateway
    function burnM(
        address minter_,
        uint256 maxPrincipalAmount_,
        uint256 maxAmount_
    ) public returns (uint112 principalAmount_, uint240 amount_) {
        if (maxPrincipalAmount_ == 0 || maxAmount_ == 0) revert ZeroBurnAmount();

        MinterState storage minterState_ = _minterStates[minter_];
        bool isActive_ = minterState_.isActive;

        // Revert early if minter has not been activated.
        if (!isActive_ && !minterState_.isDeactivated) revert InactiveMinter();

        if (isActive_) {
            // NOTE: Penalize only for missed collateral updates, not for undercollateralization.
            // Undercollateralization within one update interval is forgiven.
            _imposePenaltyIfMissedCollateralUpdates(minter_);

            (principalAmount_, amount_) = _repayForActiveMinter(
                minter_,
                UIntMath.safe112(maxPrincipalAmount_),
                UIntMath.safe240(maxAmount_)
            );

            emit BurnExecuted(minter_, principalAmount_, amount_, msg.sender);
        } else {
            amount_ = _repayForDeactivatedMinter(minter_, UIntMath.safe240(maxAmount_));

            emit BurnExecuted(minter_, amount_, msg.sender);
        }

        IMToken(mToken).burn(msg.sender, amount_); // Burn actual M tokens

        // NOTE: Above functionality already has access to `currentIndex()`, and since the completion of the burn
        //       can result in a new rate, we should update the index here to lock in that rate.
        updateIndex();
    }

    /// @inheritdoc IMinterGateway
    function cancelMint(address minter_, uint256 mintId_) external onlyApprovedValidator {
        uint48 id_ = _mintProposals[minter_].id;

        if (id_ != mintId_ || id_ == 0) revert InvalidMintProposal();

        delete _mintProposals[minter_];

        emit MintCanceled(id_, minter_, msg.sender);
    }

    /// @inheritdoc IMinterGateway
    function freezeMinter(address minter_) external onlyApprovedValidator returns (uint40 frozenUntil_) {
        unchecked {
            _minterStates[minter_].frozenUntilTimestamp = frozenUntil_ = uint40(block.timestamp) + minterFreezeTime();
        }

        emit MinterFrozen(minter_, frozenUntil_);
    }

    /// @inheritdoc IMinterGateway
    function activateMinter(address minter_) external {
        if (!isMinterApproved(minter_)) revert NotApprovedMinter();

        MinterState storage minterState_ = _minterStates[minter_];

        // NOTE: Once deactivated, a minter cannot be reactivated.
        if (minterState_.isDeactivated) revert DeactivatedMinter();

        minterState_.isActive = true;

        emit MinterActivated(minter_, msg.sender);
    }

    /// @inheritdoc IMinterGateway
    function deactivateMinter(address minter_) external onlyActiveMinter(minter_) returns (uint240 inactiveOwedM_) {
        if (isMinterApproved(minter_)) revert StillApprovedMinter();

        _imposePenaltyIfMissedCollateralUpdates(minter_);

        uint112 principalOfOwedM_ = principalOfActiveOwedMOf(minter_);

        inactiveOwedM_ = _getPresentAmount(principalOfOwedM_);

        unchecked {
            // Treat rawOwedM as principal since minter is active.
            principalOfTotalActiveOwedM -= principalOfOwedM_;
            totalInactiveOwedM += inactiveOwedM_;
        }

        emit MinterDeactivated(minter_, inactiveOwedM_, msg.sender);

        // Reset reasonable aspects of minter's state
        delete _minterStates[minter_];
        delete _mintProposals[minter_];

        // Deactivate minter.
        _minterStates[minter_].isDeactivated = true;

        _rawOwedM[minter_] = inactiveOwedM_; // Treat rawOwedM as inactive owed M since minter is now inactive.

        // NOTE: Above functionality already has access to `currentIndex()`, and since the completion of the
        //       deactivation can result in a new rate, we should update the index here to lock in that rate.
        updateIndex();
    }

    /// @inheritdoc IContinuousIndexing
    function updateIndex() public override(IContinuousIndexing, ContinuousIndexing) returns (uint128 index_) {
        // NOTE: Since the currentIndex of the Minter Gateway and mToken are constant through this context's execution
        //       (the block.timestamp is not changing) we can compute excessOwedM without updating the mToken index.
        uint240 excessOwedM_ = excessOwedM();

        if (excessOwedM_ > 0) IMToken(mToken).mint(ttgVault, excessOwedM_); // Mint M to TTG Vault.

        // NOTE: Above functionality already has access to `currentIndex()`, and since the completion of the collateral
        //       update can result in a new rate, we should update the index here to lock in that rate.
        // NOTE: With the current rate models, the minter rate does not depend on anything in the Minter Gateway
        //       or mToken, so we can update the minter rate and index here.
        index_ = super.updateIndex(); // Update minter index and rate.

        // NOTE: Given the current implementation of the mToken transfers and its rate model, while it is possible for
        //       the above mint to already have updated the mToken index if M was minted to an earning account, we want
        //       to ensure the rate provided by the mToken's rate model is locked in.
        IMToken(mToken).updateIndex(); // Update earning index and rate.
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IMinterGateway
    function totalActiveOwedM() public view returns (uint240) {
        return _getPresentAmount(principalOfTotalActiveOwedM);
    }

    /// @inheritdoc IMinterGateway
    function totalOwedM() external view returns (uint240) {
        unchecked {
            // NOTE: This can never overflow since the `mint` functions caps the principal of total owed M (active and
            //       inactive) to `type(uint112).max`. Thus, there can never be enough inactive owed M (which is an
            //       accumulations principal of active owed M values converted to present values at previous and lower
            //       indices) or active owed M to overflow this.
            return totalActiveOwedM() + totalInactiveOwedM;
        }
    }

    /// @inheritdoc IMinterGateway
    function excessOwedM() public view returns (uint240 excessOwedM_) {
        // NOTE: Can safely cast to `uint240` since we know M Token totalSupply constraints.
        uint240 totalMSupply_ = uint240(IMToken(mToken).totalSupply());

        uint240 totalOwedM_ = _getPresentAmountRoundedDown(principalOfTotalActiveOwedM, currentIndex()) +
            totalInactiveOwedM;

        unchecked {
            if (totalOwedM_ > totalMSupply_) return totalOwedM_ - totalMSupply_;
        }
    }

    /// @inheritdoc IMinterGateway
    function minterRate() external view returns (uint32) {
        return _latestRate;
    }

    /// @inheritdoc IMinterGateway
    function isActiveMinter(address minter_) external view returns (bool) {
        return _minterStates[minter_].isActive;
    }

    /// @inheritdoc IMinterGateway
    function isDeactivatedMinter(address minter_) external view returns (bool) {
        return _minterStates[minter_].isDeactivated;
    }

    /// @inheritdoc IMinterGateway
    function isFrozenMinter(address minter_) external view returns (bool) {
        return block.timestamp < _minterStates[minter_].frozenUntilTimestamp;
    }

    /// @inheritdoc IMinterGateway
    function principalOfActiveOwedMOf(address minter_) public view returns (uint112) {
        // NOTE: This should also include the principal value of unavoidable penalities. But then it would be very, if
        //       not impossible, to determine the `principalOfTotalActiveOwedM` to the same standards.
        return
            _minterStates[minter_].isActive
                ? uint112(_rawOwedM[minter_]) // Treat rawOwedM as principal since minter is active.
                : 0;
    }

    /// @inheritdoc IMinterGateway
    function activeOwedMOf(address minter_) public view returns (uint240) {
        // NOTE: This should also include the present value of unavoidable penalities. But then it would be very, if
        //       not impossible, to determine the `totalActiveOwedM` to the same standards.
        return
            _minterStates[minter_].isActive
                ? _getPresentAmount(uint112(_rawOwedM[minter_])) // Treat rawOwedM as principal since minter is active.
                : 0;
    }

    /// @inheritdoc IMinterGateway
    function maxAllowedActiveOwedMOf(address minter_) public view returns (uint256) {
        // NOTE: Since `mintRatio()` is capped at 650% (i.e. 65_000) this cannot overflow.
        unchecked {
            return _minterStates[minter_].isActive ? (uint256(collateralOf(minter_)) * mintRatio()) / ONE : 0;
        }
    }

    /// @inheritdoc IMinterGateway
    function inactiveOwedMOf(address minter_) public view returns (uint240) {
        // Treat rawOwedM as present amount since minter is inactive.
        return _minterStates[minter_].isActive ? 0 : _rawOwedM[minter_];
    }

    /// @inheritdoc IMinterGateway
    function collateralOf(address minter_) public view returns (uint240) {
        // If collateral was not updated by the deadline, assume that minter's collateral is zero.
        if (block.timestamp >= collateralExpiryTimestampOf(minter_)) return 0;

        MinterState storage minterState_ = _minterStates[minter_];
        uint240 totalPendingRetrievals_ = minterState_.totalPendingRetrievals;
        uint240 collateral_ = minterState_.collateral;

        // If the minter's total pending retrievals is greater than their collateral, then their collateral is zero.
        if (totalPendingRetrievals_ >= collateral_) return 0;

        unchecked {
            return collateral_ - totalPendingRetrievals_;
        }
    }

    /// @inheritdoc IMinterGateway
    function collateralUpdateTimestampOf(address minter_) external view returns (uint40) {
        return _minterStates[minter_].updateTimestamp;
    }

    /// @inheritdoc IMinterGateway
    function collateralPenaltyDeadlineOf(address minter_) external view returns (uint40) {
        MinterState storage minterState_ = _minterStates[minter_];
        uint32 updateCollateralInterval_ = updateCollateralInterval();

        (, uint40 missedUntil_) = _getMissedCollateralUpdateParameters(
            minterState_.updateTimestamp,
            minterState_.penalizedUntilTimestamp,
            updateCollateralInterval_
        );

        return missedUntil_ + updateCollateralInterval_;
    }

    /// @inheritdoc IMinterGateway
    function collateralExpiryTimestampOf(address minter_) public view returns (uint40) {
        unchecked {
            return _minterStates[minter_].updateTimestamp + updateCollateralInterval();
        }
    }

    /// @inheritdoc IMinterGateway
    function penalizedUntilOf(address minter_) external view returns (uint40) {
        return _minterStates[minter_].penalizedUntilTimestamp;
    }

    /// @inheritdoc IMinterGateway
    function latestProposedRetrievalTimestampOf(address minter_) external view returns (uint40) {
        return _minterStates[minter_].latestProposedRetrievalTimestamp;
    }

    /// @inheritdoc IMinterGateway
    function getLastSignatureTimestamp(address minter_, address validator_) external view returns (uint256) {
        return _lastSignatureTimestamp[minter_][validator_];
    }

    /// @inheritdoc IMinterGateway
    function getUpdateCollateralDigest(
        address minter_,
        uint256 collateral_,
        uint256[] calldata retrievalIds_,
        bytes32 metadataHash_,
        uint256 timestamp_
    ) external view returns (bytes32) {
        return _getUpdateCollateralDigest(minter_, collateral_, retrievalIds_, metadataHash_, timestamp_);
    }

    /// @inheritdoc IMinterGateway
    function mintProposalOf(
        address minter_
    ) external view returns (uint48 mintId_, uint40 createdAt_, address destination_, uint240 amount_) {
        mintId_ = _mintProposals[minter_].id;
        createdAt_ = _mintProposals[minter_].createdAt;
        destination_ = _mintProposals[minter_].destination;
        amount_ = _mintProposals[minter_].amount;
    }

    /// @inheritdoc IMinterGateway
    function pendingCollateralRetrievalOf(address minter_, uint256 retrievalId_) external view returns (uint240) {
        return
            _minterStates[minter_].isDeactivated
                ? 0
                : _pendingCollateralRetrievals[minter_][UIntMath.safe48(retrievalId_)];
    }

    /// @inheritdoc IMinterGateway
    function totalPendingCollateralRetrievalOf(address minter_) external view returns (uint240) {
        return _minterStates[minter_].isDeactivated ? 0 : _minterStates[minter_].totalPendingRetrievals;
    }

    /// @inheritdoc IMinterGateway
    function frozenUntilOf(address minter_) external view returns (uint40) {
        return _minterStates[minter_].frozenUntilTimestamp;
    }

    /* ============ TTG Registrar Reader Functions ============ */

    /// @inheritdoc IMinterGateway
    function isMinterApproved(address minter_) public view returns (bool) {
        return TTGRegistrarReader.isApprovedMinter(ttgRegistrar, minter_);
    }

    /// @inheritdoc IMinterGateway
    function isValidatorApproved(address validator_) public view returns (bool) {
        return TTGRegistrarReader.isApprovedValidator(ttgRegistrar, validator_);
    }

    /// @inheritdoc IMinterGateway
    function updateCollateralInterval() public view returns (uint32) {
        return
            UIntMath.max32(
                UIntMath.bound32(TTGRegistrarReader.getUpdateCollateralInterval(ttgRegistrar)),
                MIN_UPDATE_COLLATERAL_INTERVAL
            );
    }

    /// @inheritdoc IMinterGateway
    function updateCollateralValidatorThreshold() public view returns (uint256) {
        return TTGRegistrarReader.getUpdateCollateralValidatorThreshold(ttgRegistrar);
    }

    /// @inheritdoc IMinterGateway
    function mintRatio() public view returns (uint32) {
        // NOTE: It is possible for the mint ratio to be greater than 100%, but capped at 650%.
        return UIntMath.min32(MAX_MINT_RATIO, UIntMath.bound32(TTGRegistrarReader.getMintRatio(ttgRegistrar)));
    }

    /// @inheritdoc IMinterGateway
    function mintDelay() public view returns (uint32) {
        return UIntMath.bound32(TTGRegistrarReader.getMintDelay(ttgRegistrar));
    }

    /// @inheritdoc IMinterGateway
    function mintTTL() public view returns (uint32) {
        return UIntMath.bound32(TTGRegistrarReader.getMintTTL(ttgRegistrar));
    }

    /// @inheritdoc IMinterGateway
    function minterFreezeTime() public view returns (uint32) {
        return UIntMath.bound32(TTGRegistrarReader.getMinterFreezeTime(ttgRegistrar));
    }

    /// @inheritdoc IMinterGateway
    function penaltyRate() public view returns (uint32) {
        return UIntMath.bound32(TTGRegistrarReader.getPenaltyRate(ttgRegistrar));
    }

    /// @inheritdoc IMinterGateway
    function rateModel() public view returns (address) {
        return TTGRegistrarReader.getMinterRateModel(ttgRegistrar);
    }

    /// @inheritdoc IContinuousIndexing
    function currentIndex() public view override(ContinuousIndexing, IContinuousIndexing) returns (uint128) {
        // NOTE: Safe to use unchecked here, since `block.timestamp` is always greater than `latestUpdateTimestamp`.
        unchecked {
            return
                // NOTE: Cap the index to `type(uint128).max` to prevent overflow in present value math.
                UIntMath.bound128(
                    ContinuousIndexingMath.multiplyIndicesUp(
                        latestIndex,
                        ContinuousIndexingMath.getContinuousIndex(
                            ContinuousIndexingMath.convertFromBasisPoints(_latestRate),
                            uint32(block.timestamp - latestUpdateTimestamp)
                        )
                    )
                );
        }
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev    Imposes penalty on an active minter. Calling this for an inactive minter will break accounting.
     * @param  minter_                 The address of the minter.
     * @param  principalOfPenaltyBase_ The principal of the base for penalization.
     * @return The principal of the imposed penalty.
     */
    function _imposePenalty(address minter_, uint152 principalOfPenaltyBase_) internal returns (uint112) {
        if (principalOfPenaltyBase_ == 0) return 0;

        uint32 penaltyRate_ = penaltyRate();

        if (penaltyRate_ == 0) return 0;

        unchecked {
            uint256 penaltyPrincipal_ = (uint256(principalOfPenaltyBase_) * penaltyRate_) / ONE;

            // As an edge case precaution, cap the penalty principal such that the resulting principal of total active
            // owed M plus the penalty principal is not greater than the max uint112.
            uint256 newPrincipalOfTotalActiveOwedM_ = principalOfTotalActiveOwedM + penaltyPrincipal_;

            if (newPrincipalOfTotalActiveOwedM_ > type(uint112).max) {
                penaltyPrincipal_ = type(uint112).max - principalOfTotalActiveOwedM;
                newPrincipalOfTotalActiveOwedM_ = type(uint112).max;
            }

            // Calculate and add penalty principal to total minter's principal of active owed M
            principalOfTotalActiveOwedM = uint112(newPrincipalOfTotalActiveOwedM_);

            _rawOwedM[minter_] += uint112(penaltyPrincipal_); // Treat rawOwedM as principal since minter is active.

            return uint112(penaltyPrincipal_);
        }
    }

    /**
     * @dev   Imposes penalty if minter missed collateral updates.
     * @param minter_ The address of the minter.
     */
    function _imposePenaltyIfMissedCollateralUpdates(address minter_) internal {
        uint112 principalOfActiveOwedM_ = principalOfActiveOwedMOf(minter_);

        if (principalOfActiveOwedM_ == 0) return;

        MinterState storage minterState_ = _minterStates[minter_];

        (uint40 missedIntervals_, uint40 missedUntil_) = _getMissedCollateralUpdateParameters(
            minterState_.updateTimestamp,
            minterState_.penalizedUntilTimestamp,
            updateCollateralInterval()
        );

        if (missedIntervals_ == 0) return;

        // Save until when the minter has been penalized for missed intervals to prevent double penalizing them.
        minterState_.penalizedUntilTimestamp = missedUntil_;

        uint112 penaltyPrincipal_ = _imposePenalty(minter_, uint152(principalOfActiveOwedM_) * missedIntervals_);

        if (penaltyPrincipal_ == 0) return;

        emit MissedIntervalsPenaltyImposed(minter_, missedIntervals_, _getPresentAmount(penaltyPrincipal_));
    }

    /**
     * @dev   Imposes penalty if minter is undercollateralized.
     * @param minter_       The address of the minter.
     * @param newTimestamp_ The timestamp of the collateral update.
     */
    function _imposePenaltyIfUndercollateralized(address minter_, uint40 newTimestamp_) internal {
        uint112 principalOfActiveOwedM_ = principalOfActiveOwedMOf(minter_);

        if (principalOfActiveOwedM_ == 0) return;

        uint256 maxAllowedActiveOwedM_ = maxAllowedActiveOwedMOf(minter_);

        // If the minter's max allowed active owed M is greater than `type(uint240).max`, then it's definitely greater
        // than the max possible active owed M for the minter, which is capped at `type(uint240).max`.
        if (maxAllowedActiveOwedM_ >= type(uint240).max) return;

        // NOTE: Round the principal down in favor of the protocol since this is a max applied to the minter.
        uint112 principalOfMaxAllowedActiveOwedM_ = _getPrincipalAmountRoundedDown(uint240(maxAllowedActiveOwedM_));

        // If the minter is not undercollateralized, then no penalty is imposed.
        if (principalOfMaxAllowedActiveOwedM_ >= principalOfActiveOwedM_) return;

        MinterState storage minterState_ = _minterStates[minter_];

        uint40 penalizeFrom_ = UIntMath.max40(minterState_.updateTimestamp, minterState_.penalizedUntilTimestamp);

        if (newTimestamp_ <= penalizeFrom_) return;

        unchecked {
            uint40 timeSpan_ = newTimestamp_ - penalizeFrom_;

            uint112 principalOfExcessOwedM_ = principalOfActiveOwedM_ - principalOfMaxAllowedActiveOwedM_;

            // NOTE: `newTimestamp_ - penalizeFrom_` will never be larger than `updateCollateralInterval_` since this
            //       function is only called after `_imposePenaltyIfMissedCollateralUpdates`, which ensures that the
            //       `penalizedUntilTimestamp` is within one `updateCollateralInterval_` of the `newTimestamp_`.
            //
            // NOTE: `updateCollateralInterval()` never equals 0, so the division is safe.
            //       Its minimum is capped at `MIN_UPDATE_COLLATERAL_INTERVAL`.
            uint112 penaltyPrincipal_ = _imposePenalty(
                minter_,
                (principalOfExcessOwedM_ * timeSpan_) / updateCollateralInterval()
            );

            if (penaltyPrincipal_ == 0) return;

            emit UndercollateralizedPenaltyImposed(
                minter_,
                _getPresentAmount(principalOfExcessOwedM_),
                timeSpan_,
                _getPresentAmount(penaltyPrincipal_)
            );
        }
    }

    /**
     * @dev    Repays active minter's owed M.
     * @param  minter_             The address of the minter.
     * @param  maxPrincipalAmount_ The maximum principal amount of active owed M to repay.
     * @param  maxAmount_          The maximum amount of active owed M to repay.
     * @return principalAmount_    The principal amount of active owed M that was actually repaid.
     * @return amount_             The amount of active owed M that was actually repaid.
     */
    function _repayForActiveMinter(
        address minter_,
        uint112 maxPrincipalAmount_,
        uint240 maxAmount_
    ) internal returns (uint112 principalAmount_, uint240 amount_) {
        principalAmount_ = UIntMath.min112(principalOfActiveOwedMOf(minter_), maxPrincipalAmount_);
        amount_ = _getPresentAmount(principalAmount_);

        if (amount_ > maxAmount_) revert ExceedsMaxRepayAmount(amount_, maxAmount_);

        unchecked {
            // Treat rawOwedM as principal since `principalAmount_` would only be non-zero for an active minter.
            _rawOwedM[minter_] -= principalAmount_;
            principalOfTotalActiveOwedM -= principalAmount_;
        }
    }

    /**
     * @dev    Repays deactivated minter's owed M.
     * @param  minter_    The address of the minter.
     * @param  maxAmount_ The maximum amount of inactive owed M to repay.
     * @return amount_    The amount of inactive owed M that was actually repaid.
     */
    function _repayForDeactivatedMinter(address minter_, uint240 maxAmount_) internal returns (uint240 amount_) {
        amount_ = UIntMath.min240(inactiveOwedMOf(minter_), maxAmount_);

        unchecked {
            // Treat rawOwedM as present amount since `amount_` would only be non-zero for an inactive minter.
            _rawOwedM[minter_] -= amount_;
            totalInactiveOwedM -= amount_;
        }
    }

    /**
     * @dev    Resolves the collateral retrieval IDs and updates the total pending collateral retrieval amount.
     * @param  minter_                           The address of the minter.
     * @param  retrievalIds_                     The list of outstanding collateral retrieval IDs to resolve.
     * @return totalResolvedCollateralRetrieval_ The total amount of collateral retrieval resolved.
     */
    function _resolvePendingRetrievals(
        address minter_,
        uint256[] calldata retrievalIds_
    ) internal returns (uint240 totalResolvedCollateralRetrieval_) {
        for (uint256 index_; index_ < retrievalIds_.length; ++index_) {
            uint48 retrievalId_ = UIntMath.safe48(retrievalIds_[index_]);
            uint240 pendingCollateralRetrieval_ = _pendingCollateralRetrievals[minter_][retrievalId_];

            if (pendingCollateralRetrieval_ == 0) continue;

            unchecked {
                // NOTE: The `proposeRetrieval` function already ensures that the sum of all
                // `_pendingCollateralRetrievals` is not larger than `type(uint240).max`.
                totalResolvedCollateralRetrieval_ += pendingCollateralRetrieval_;
            }

            delete _pendingCollateralRetrievals[minter_][retrievalId_];

            emit RetrievalResolved(retrievalId_, minter_);
        }

        unchecked {
            // NOTE: The `proposeRetrieval` function already ensures that `totalPendingRetrievals` is the sum of all
            // `_pendingCollateralRetrievals`.
            _minterStates[minter_].totalPendingRetrievals -= totalResolvedCollateralRetrieval_;
        }
    }

    /**
     * @dev   Updates the collateral amount and update timestamp for the minter.
     * @param minter_       The address of the minter.
     * @param amount_       The amount of collateral.
     * @param newTimestamp_ The timestamp of the collateral update.
     */
    function _updateCollateral(address minter_, uint240 amount_, uint40 newTimestamp_) internal {
        MinterState storage minterState_ = _minterStates[minter_];

        // The earliest allowed timestamp for a collateral update is the maximum of:
        //   - the last update timestamp,
        //   - the latest proposed retrieval timestamp, and
        //   - the current timestamp minus the update collateral interval.
        unchecked {
            // NOTE: Cannot underflow since `min40` is applied when `updateCollateralInterval()` > `block.timestamp`.
            uint40 earliestAllowedTimestamp_ = UIntMath.max40(
                UIntMath.max40(minterState_.updateTimestamp, minterState_.latestProposedRetrievalTimestamp),
                uint40(block.timestamp) - UIntMath.min40(updateCollateralInterval(), uint40(block.timestamp))
            );

            if (newTimestamp_ <= earliestAllowedTimestamp_) {
                revert StaleCollateralUpdate(newTimestamp_, earliestAllowedTimestamp_);
            }
        }

        minterState_.collateral = amount_;
        minterState_.updateTimestamp = newTimestamp_;
    }

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the penalization base and the penalized until timestamp.
     * @param  lastUpdateTimestamp_ The last timestamp at which the minter updated their collateral.
     * @param  lastPenalizedUntil_  The timestamp before which the minter shouldn't be penalized for missed updates.
     * @param  updateInterval_      The update collateral interval.
     * @return missedIntervals_     The number of missed update intervals.
     * @return missedUntil_         The timestamp until which `missedIntervals_` covers,
     *                              even if `missedIntervals_` is 0.
     */
    function _getMissedCollateralUpdateParameters(
        uint40 lastUpdateTimestamp_,
        uint40 lastPenalizedUntil_,
        uint32 updateInterval_
    ) internal view returns (uint40 missedIntervals_, uint40 missedUntil_) {
        uint40 penalizeFrom_ = UIntMath.max40(lastUpdateTimestamp_, lastPenalizedUntil_);

        // If brand new minter then there is no missed interval charge at all.
        if (lastUpdateTimestamp_ == 0) return (0, penalizeFrom_);

        uint40 timeElapsed_ = uint40(block.timestamp) - penalizeFrom_;

        if (timeElapsed_ < updateInterval_) return (0, penalizeFrom_);

        unchecked {
            // NOTE: `updateInterval_` never equals 0, so the division is safe.
            //       Its minimum is capped at `MIN_UPDATE_COLLATERAL_INTERVAL`.
            missedIntervals_ = timeElapsed_ / updateInterval_;

            // NOTE: Cannot really overflow a `uint40` since `missedIntervals_ * updateInterval_ <= timeElapsed_`.
            missedUntil_ = penalizeFrom_ + (missedIntervals_ * updateInterval_);
        }
    }

    /**
     * @dev    Returns the present amount (rounded up) given the principal amount, using the current index.
     *         All present amounts are rounded up in favor of the protocol, since they are owed.
     * @param  principalAmount_ The principal amount.
     * @return The present amount.
     */
    function _getPresentAmount(uint112 principalAmount_) internal view returns (uint240) {
        return _getPresentAmountRoundedUp(principalAmount_, currentIndex());
    }

    /**
     * @dev    Returns the EIP-712 digest for updateCollateral method.
     * @param  minter_       The address of the minter.
     * @param  collateral_   The amount of collateral.
     * @param  retrievalIds_ The list of outstanding collateral retrieval IDs to resolve.
     * @param  metadataHash_ The hash of metadata of the collateral update, reserved for future informational use.
     * @param  timestamp_    The timestamp of the collateral update.
     * @return The EIP-712 digest.
     */
    function _getUpdateCollateralDigest(
        address minter_,
        uint256 collateral_,
        uint256[] calldata retrievalIds_,
        bytes32 metadataHash_,
        uint256 timestamp_
    ) internal view returns (bytes32) {
        return
            _getDigest(
                keccak256(
                    abi.encode(
                        UPDATE_COLLATERAL_TYPEHASH,
                        minter_,
                        collateral_,
                        keccak256(abi.encodePacked(retrievalIds_)),
                        metadataHash_,
                        timestamp_
                    )
                )
            );
    }

    /// @dev Returns the current rate from the rate model contract.
    function _rate() internal view override returns (uint32 rate_) {
        (bool success_, bytes memory returnData_) = rateModel().staticcall(
            abi.encodeWithSelector(IRateModel.rate.selector)
        );

        rate_ = (success_ && returnData_.length >= 32) ? UIntMath.bound32(abi.decode(returnData_, (uint256))) : 0;
    }

    /**
     * @dev   Reverts if minter is frozen by validator.
     * @param minter_ The address of the minter
     */
    function _revertIfFrozenMinter(address minter_) internal view {
        if (block.timestamp < _minterStates[minter_].frozenUntilTimestamp) revert FrozenMinter();
    }

    /**
     * @dev   Reverts if minter is inactive.
     * @param minter_ The address of the minter
     */
    function _revertIfInactiveMinter(address minter_) internal view {
        if (!_minterStates[minter_].isActive) revert InactiveMinter();
    }

    /**
     * @dev   Reverts if validator is not approved.
     * @param validator_ The address of the validator
     */
    function _revertIfNotApprovedValidator(address validator_) internal view {
        if (!isValidatorApproved(validator_)) revert NotApprovedValidator(validator_);
    }

    /**
     * @dev   Reverts if minter position will be undercollateralized after changes.
     * @param minter_          The address of the minter
     * @param additionalOwedM_ The amount of additional owed M the action will add to minter's position
     */
    function _revertIfUndercollateralized(address minter_, uint240 additionalOwedM_) internal view {
        uint256 maxAllowedActiveOwedM_ = maxAllowedActiveOwedMOf(minter_);

        unchecked {
            uint256 finalActiveOwedM_ = uint256(activeOwedMOf(minter_)) + additionalOwedM_;

            if (finalActiveOwedM_ > maxAllowedActiveOwedM_) {
                //NOTE: remove by fuzzer, not checking collateral on this stage
                // revert Undercollateralized(finalActiveOwedM_, maxAllowedActiveOwedM_);
            }
        }
    }

    /**
     * @dev    Checks that enough valid unique signatures were provided.
     * @param  minter_       The address of the minter.
     * @param  collateral_   The amount of collateral.
     * @param  retrievalIds_ The list of outstanding collateral retrieval IDs to resolve.
     * @param  metadataHash_ The hash of metadata of the collateral update, reserved for future informational use.
     * @param  validators_   The list of validators.
     * @param  timestamps_   The list of validator timestamps for the collateral update signatures.
     * @param  signatures_   The list of signatures.
     * @return minTimestamp_ The minimum timestamp across all valid timestamps with valid signatures.
     */
    function _verifyValidatorSignatures(
        address minter_,
        uint256 collateral_,
        uint256[] calldata retrievalIds_,
        bytes32 metadataHash_,
        address[] calldata validators_,
        uint256[] calldata timestamps_,
        bytes[] calldata signatures_
    ) internal returns (uint40 minTimestamp_) {
        minTimestamp_ = uint40(block.timestamp);

        uint256 validCount_;

        for (uint256 index_; index_ < signatures_.length; ++index_) {
            unchecked {
                // Check that validator address is unique and not accounted for
                // NOTE: We revert here because this failure is entirely within the minter's control.
                if (index_ > 0 && validators_[index_] <= validators_[index_ - 1]) revert InvalidSignatureOrder();
            }

            if (
                !_verifyValidatorSignature(
                    minter_,
                    collateral_,
                    retrievalIds_,
                    metadataHash_,
                    validators_[index_],
                    timestamps_[index_],
                    signatures_[index_]
                )
            ) continue;

            // Find minimum between all valid timestamps for valid signatures.
            minTimestamp_ = UIntMath.min40(minTimestamp_, uint40(timestamps_[index_]));

            unchecked {
                ++validCount_;
            }
        }

        uint256 requiredThreshold_ = updateCollateralValidatorThreshold();

        if (validCount_ < requiredThreshold_) revert NotEnoughValidSignatures(validCount_, requiredThreshold_);
    }

    /**
     * @dev    Checks that a signature is a valid validator signature.
     * @param  minter_       The address of the minter.
     * @param  collateral_   The amount of collateral.
     * @param  retrievalIds_ The list of outstanding collateral retrieval IDs to resolve.
     * @param  metadataHash_ The hash of metadata of the collateral update, reserved for future informational use.
     * @param  validator_    The address of a validator.
     * @param  timestamp_    The timestamp for the collateral update signature.
     * @param  signature_    The signature from the validator.
     * @return Whether the signature is a valid validator signature or not.
     */
    function _verifyValidatorSignature(
        address minter_,
        uint256 collateral_,
        uint256[] calldata retrievalIds_,
        bytes32 metadataHash_,
        address validator_,
        uint256 timestamp_,
        bytes calldata signature_
    ) internal returns (bool) {
        // Check that the timestamp is not 0.
        // NOTE: Revert here because this failure is entirely within the minter's control.
        if (timestamp_ == 0) revert ZeroTimestamp();

        // Check that the timestamp is not in the future.
        // NOTE: Revert here because this failure is entirely within the minter's control.
        if (timestamp_ > uint40(block.timestamp)) revert FutureTimestamp();

        uint256 lastTimestamp_ = _lastSignatureTimestamp[minter_][validator_];

        // Check that the timestamp is not older than the last signature timestamp.
        // NOTE: Revert here because this failure is entirely within the minter's control.
        if (timestamp_ <= lastTimestamp_) revert OutdatedValidatorTimestamp(validator_, timestamp_, lastTimestamp_);

        // Check that validator is approved by TTG.
        if (!isValidatorApproved(validator_)) return false;

        // Check that ECDSA or ERC1271 signatures for given digest are valid.
        if (
            !SignatureChecker.isValidSignature(
                validator_,
                _getUpdateCollateralDigest(minter_, collateral_, retrievalIds_, metadataHash_, timestamp_),
                signature_
            )
        ) return false;

        // Save the last signature timestamp for the minter and validator combination.
        _lastSignatureTimestamp[minter_][validator_] = timestamp_;

        return true;
    }
}
