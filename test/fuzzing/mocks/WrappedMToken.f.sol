// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/libs/Bytes32String.sol

/**
 * @title  A library to convert between string and bytes32 (assuming 32 characters or less).
 * @author M^0 Labs
 */
library Bytes32String {
    function toBytes32(string memory input_) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked(input_));
    }

    function toString(bytes32 input_) internal pure returns (string memory) {
        uint256 length_;

        while (length_ < 32 && uint8(input_[length_]) != 0) {
            ++length_;
        }

        bytes memory name_ = new bytes(length_);

        for (uint256 index_; index_ < length_; ++index_) {
            name_[index_] = input_[index_];
        }

        return string(name_);
    }
}

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/interfaces/IERC1271.sol

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

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/interfaces/IERC20.sol

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

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/interfaces/IERC712.sol

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
     * @param  deadline  The deadline of the signature.
     * @param  timestamp The current timestamp.
     */
    error SignatureExpired(uint256 deadline, uint256 timestamp);

    /// @notice Revert message when a recovered signer does not match the account being purported to have signed.
    error SignerMismatch();

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the EIP712 domain separator used in the encoding of a signed digest.
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// test/fuzzing/mocks/wrappedMToken.sol/src/interfaces/IMTokenLike.sol

/**
 * @title  Subset of M Token interface required for source contracts.
 * @author M^0 Labs
 */
interface IMTokenLike {
    /* ============ Interactive Functions ============ */

    /**
     * @notice Allows a calling account to transfer `amount` tokens to `recipient`.
     * @param  recipient The address of the recipient who's token balance will be incremented.
     * @param  amount    The amount of tokens being transferred.
     * @return success   Whether or not the transfer was successful.
     */
    function transfer(address recipient, uint256 amount) external returns (bool success);

    /**
     * @notice Allows a calling account to transfer `amount` tokens from `sender`, with allowance, to a `recipient`.
     * @param  sender    The address of the sender who's token balance will be decremented.
     * @param  recipient The address of the recipient who's token balance will be incremented.
     * @param  amount    The amount of tokens being transferred.
     * @return success   Whether or not the transfer was successful.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool success);

    /// @notice Starts earning for caller if allowed by TTG.
    function startEarning() external;

    /// @notice Stops earning for caller.
    function stopEarning() external;

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Checks if account is an earner.
     * @param  account The account to check.
     * @return earning True if account is an earner, false otherwise.
     */
    function isEarning(address account) external view returns (bool earning);

    /**
     * @notice Returns the token balance of `account`.
     * @param  account The address of some account.
     * @return balance The token balance of `account`.
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /// @notice The current index that would be written to storage if `updateIndex` is called.
    function currentIndex() external view returns (uint128 currentIndex);

    /// @notice The address of the TTG Registrar contract.
    function ttgRegistrar() external view returns (address ttgRegistrar);
}

// test/fuzzing/mocks/wrappedMToken.sol/src/interfaces/IMigratable.sol

/**
 * @title  Interface for exposing the ability to migrate a contract, extending the ERC-1967 interface.
 * @author M^0 Labs
 */
interface IMigratable {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a migration to a new implementation is performed.
     * @param  migrator          The address that performed the migration.
     * @param  oldImplementation The address of the old implementation.
     * @param  newImplementation The address of the new implementation.
     */
    event Migrated(address indexed migrator, address indexed oldImplementation, address indexed newImplementation);

    /**
     * @notice Emitted when the implementation address for the proxy is changed.
     * @param  implementation The address of the new implementation for the proxy.
     */
    event Upgraded(address indexed implementation);

    /// @notice Emitted when calling `stopEarning` for an account approved as earner by TTG.
    error InvalidMigrator();

    /// @notice Emitted when the delegatecall to a migrator fails.
    error MigrationFailed();

    /// @notice Emitted when the zero address is passed as a migrator.
    error ZeroMigrator();

    /* ============ Interactive Functions ============ */

    /// @notice Performs an arbitrarily defined migration.
    function migrate() external;

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the address of the current implementation contract.
    function implementation() external view returns (address implementation);
}

// test/fuzzing/mocks/wrappedMToken.sol/src/interfaces/IRegistrarLike.sol

/**
 * @title  Subset of Registrar interface required for source contracts.
 * @author M^0 Labs
 */
interface IRegistrarLike {
    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns the value of `key`.
     * @param  key   Some key.
     * @return value Some value.
     */
    function get(bytes32 key) external view returns (bytes32 value);

    /**
     * @notice Returns whether `list` contains `account` or not.
     * @param  list     The key for some list.
     * @param  account  The address of some account.
     * @return contains Whether `list` contains `account` or not.
     */
    function listContains(bytes32 list, address account) external view returns (bool contains);

    /// @notice Returns the address of the Vault.
    function vault() external view returns (address vault);
}

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/libs/UIntMath.sol

/**
 * @title  Library to perform safe math operations on uint types
 * @author M^0 Labs
 */
library UIntMath {
    /* ============ Custom Errors ============ */

    /// @notice Emitted when a passed value is greater than the maximum value of uint16.
    error InvalidUInt16();

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
     * @notice Casts a given uint256 value to a uint16,
     *         ensuring that it is less than or equal to the maximum uint16 value.
     * @param  n The value to check.
     * @return The value casted to uint16.
     */
    function safe16(uint256 n) internal pure returns (uint16) {
        if (n > type(uint16).max) revert InvalidUInt16();
        return uint16(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint40,
     *         ensuring that it is less than or equal to the maximum uint40 value.
     * @param  n The value to check.
     * @return The value casted to uint40.
     */
    function safe40(uint256 n) internal pure returns (uint40) {
        if (n > type(uint40).max) revert InvalidUInt40();
        return uint40(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint48,
     *         ensuring that it is less than or equal to the maximum uint48 value.
     * @param  n The value to check.
     * @return The value casted to uint48.
     */
    function safe48(uint256 n) internal pure returns (uint48) {
        if (n > type(uint48).max) revert InvalidUInt48();
        return uint48(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint112,
     *         ensuring that it is less than or equal to the maximum uint112 value.
     * @param  n The value to check.
     * @return The value casted to uint112.
     */
    function safe112(uint256 n) internal pure returns (uint112) {
        if (n > type(uint112).max) revert InvalidUInt112();
        return uint112(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint128,
     *         ensuring that it is less than or equal to the maximum uint128 value.
     * @param  n The value to check.
     * @return The value casted to uint128.
     */
    function safe128(uint256 n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    /**
     * @notice Casts a given uint256 value to a uint240,
     *         ensuring that it is less than or equal to the maximum uint240 value.
     * @param  n The value to check.
     * @return The value casted to uint240.
     */
    function safe240(uint256 n) internal pure returns (uint240) {
        if (n > type(uint240).max) revert InvalidUInt240();
        return uint240(n);
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint32 value.
     * @param  n The value to check.
     * @return The value limited to within uint32 bounds.
     */
    function bound32(uint256 n) internal pure returns (uint32) {
        return uint32(min256(n, uint256(type(uint32).max)));
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint112 value.
     * @param  n The value to check.
     * @return The value limited to within uint112 bounds.
     */
    function bound112(uint256 n) internal pure returns (uint112) {
        return uint112(min256(n, uint256(type(uint112).max)));
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint128 value.
     * @param  n The value to check.
     * @return The value limited to within uint128 bounds.
     */
    function bound128(uint256 n) internal pure returns (uint128) {
        return uint128(min256(n, uint256(type(uint128).max)));
    }

    /**
     * @notice Limits a given uint256 value to the maximum uint240 value.
     * @param  n The value to check.
     * @return The value limited to within uint240 bounds.
     */
    function bound240(uint256 n) internal pure returns (uint240) {
        return uint240(min256(n, uint256(type(uint240).max)));
    }

    /**
     * @notice Compares two uint32 values and returns the larger one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The larger value.
     */
    function max32(uint32 a_, uint32 b_) internal pure returns (uint32) {
        return a_ > b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint40 values and returns the larger one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The larger value.
     */
    function max40(uint40 a_, uint40 b_) internal pure returns (uint40) {
        return a_ > b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint32 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min32(uint32 a_, uint32 b_) internal pure returns (uint32) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint40 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min40(uint40 a_, uint40 b_) internal pure returns (uint40) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint240 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min240(uint240 a_, uint240 b_) internal pure returns (uint240) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint112 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min112(uint112 a_, uint112 b_) internal pure returns (uint112) {
        return a_ < b_ ? a_ : b_;
    }

    /**
     * @notice Compares two uint256 values and returns the lesser one.
     * @param  a_  Value to check.
     * @param  b_  Value to check.
     * @return The lesser value.
     */
    function min256(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ < b_ ? a_ : b_;
    }
}

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/interfaces/IERC712Extended.sol

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

// test/fuzzing/mocks/wrappedMToken.sol/src/libs/IndexingMath.sol

/**
 * @title  Helper library for indexing math functions.
 * @author M^0 Labs
 */
library IndexingMath {
    /* ============ Variables ============ */

    /// @notice The scaling of indexes for exponent math.
    uint56 internal constant EXP_SCALED_ONE = 1e12;

    /* ============ Custom Errors ============ */

    /// @notice Emitted when a division by zero occurs.
    error DivisionByZero();

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @notice Helper function to calculate `(x * EXP_SCALED_ONE) / y`, rounded down.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function divide240By128Down(uint240 x_, uint128 y_) internal pure returns (uint112) {
        if (y_ == 0) revert DivisionByZero();

        unchecked {
            // NOTE: While `uint256(x) * EXP_SCALED_ONE` can technically overflow, these divide/multiply functions are
            //       only used for the purpose of principal/present amount calculations for continuous indexing, and
            //       so for an `x` to be large enough to overflow this, it would have to be a possible result of
            //       `multiply112By128Down` or `multiply112By128Up`, which would already satisfy
            //       `uint256(x) * EXP_SCALED_ONE < type(uint240).max`.
            return UIntMath.safe112((uint256(x_) * EXP_SCALED_ONE) / y_);
        }
    }

    /**
     * @notice Helper function to calculate `(x * EXP_SCALED_ONE) / y`, rounded up.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function divide240By128Up(uint240 x_, uint128 y_) internal pure returns (uint112) {
        if (y_ == 0) revert DivisionByZero();

        unchecked {
            // NOTE: While `uint256(x) * EXP_SCALED_ONE` can technically overflow, these divide/multiply functions are
            //       only used for the purpose of principal/present amount calculations for continuous indexing, and
            //       so for an `x` to be large enough to overflow this, it would have to be a possible result of
            //       `multiply112By128Down` or `multiply112By128Up`, which would already satisfy
            //       `uint256(x) * EXP_SCALED_ONE < type(uint240).max`.
            return UIntMath.safe112(((uint256(x_) * EXP_SCALED_ONE) + y_ - 1) / y_);
        }
    }

    /**
     * @notice Helper function to calculate `(x * y) / EXP_SCALED_ONE`, rounded down.
     * @dev    Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
     */
    function multiply112By128Down(uint112 x_, uint128 y_) internal pure returns (uint240) {
        unchecked {
            return uint240((uint256(x_) * y_) / EXP_SCALED_ONE);
        }
    }

    /**
     * @dev    Returns the present amount (rounded down) given the principal amount and an index.
     * @param  principalAmount_ The principal amount.
     * @param  index_           An index.
     * @return The present amount rounded down.
     */
    function getPresentAmountRoundedDown(uint112 principalAmount_, uint128 index_) internal pure returns (uint240) {
        return multiply112By128Down(principalAmount_, index_);
    }

    /**
     * @dev    Returns the principal amount given the present amount, using the current index.
     * @param  presentAmount_ The present amount.
     * @param  index_         An index.
     * @return The principal amount rounded down.
     */
    function getPrincipalAmountRoundedDown(uint240 presentAmount_, uint128 index_) internal pure returns (uint112) {
        return divide240By128Down(presentAmount_, index_);
    }

    /**
     * @dev    Returns the principal amount given the present amount, using the current index.
     * @param  presentAmount_ The present amount.
     * @param  index_         An index.
     * @return The principal amount rounded up.
     */
    function getPrincipalAmountRoundedUp(uint240 presentAmount_, uint128 index_) internal pure returns (uint112) {
        return divide240By128Up(presentAmount_, index_);
    }
}

// test/fuzzing/mocks/wrappedMToken.sol/src/Migratable.sol

/**
 * @title  Abstract implementation for exposing the ability to migrate a contract, extending ERC-1967.
 * @author M^0 Labs
 */
abstract contract Migratable is IMigratable {
    /* ============ Variables ============ */

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    uint256 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMigratable
    function migrate() external {
        _migrate(_getMigrator());
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IMigratable
    function implementation() public view returns (address implementation_) {
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Performs an arbitrary migration by delegate-calling `migrator_`.
     * @param migrator_ The address of a migrator contract.
     */
    function _migrate(address migrator_) internal {
        if (migrator_ == address(0)) revert ZeroMigrator();

        if (migrator_.code.length == 0) revert InvalidMigrator();

        address oldImplementation_ = implementation();

        (bool success_, ) = migrator_.delegatecall("");
        if (!success_) revert MigrationFailed();

        address newImplementation_ = implementation();

        emit Migrated(migrator_, oldImplementation_, newImplementation_);

        // NOTE: Redundant event emitted to conform to the EIP-1967 standard.
        emit Upgraded(newImplementation_);
    }

    /* ============ Internal View/Pure Functions ============ */

    /// @dev Returns the address of a migrator contract.
    function _getMigrator() internal view virtual returns (address migrator_);
}

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/libs/SignatureChecker.sol

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
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeCall(IERC1271.isValidSignature, (digest, signature))
        );

        return
            success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector);
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
     * @param  signer  The address of the account purported to have signed.
     * @param  digest  The hash of the data that was signed.
     * @param  r       An ECDSA/secp256k1 signature parameter.
     * @param  vs      An ECDSA/secp256k1 short signature parameter.
     * @return         Whether the signature is valid or not.
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

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/interfaces/IStatefulERC712.sol

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

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/interfaces/IERC3009.sol

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

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/ERC712Extended.sol

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

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/interfaces/IERC20Extended.sol

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
     * @param  deadline The last block number where the signature is still valid.
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
     * @param  deadline  The last block number where the signature is still valid.
     * @param  signature An arbitrary signature (EIP-712).
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, bytes memory signature) external;

    /* ============ View/Pure Functions ============ */

    /// @notice Returns the EIP712 typehash used in the encoding of the digest for the permit function.
    function PERMIT_TYPEHASH() external view returns (bytes32);
}

// test/fuzzing/mocks/wrappedMToken.sol/src/interfaces/IWrappedMToken.sol

/**
 * @title  Wrapped M Token interface extending Extended ERC20.
 * @author M^0 Labs
 */
interface IWrappedMToken is IMigratable, IERC20Extended {
    /* ============ Events ============ */

    /**
     * @notice Emitted when some yield is claim for `account` to `recipient`.
     * @param  account   The account under which yield was generated.
     * @param  recipient The account that received the yield.
     * @param  yield     The amount of yield claimed.
     */
    event Claimed(address indexed account, address indexed recipient, uint240 yield);

    /**
     * @notice Emitted when earning is enabled for the entire wrapper.
     * @param  index The index at the moment earning is enabled.
     */
    event EarningEnabled(uint128 index);

    /**
     * @notice Emitted when earning is disabled for the entire wrapper.
     * @param  index The index at the moment earning is disabled.
     */
    event EarningDisabled(uint128 index);

    /**
     * @notice Emitted when the wrapper's excess M is claimed.
     * @param  excess The amount of excess M claimed.
     */
    event ExcessClaimed(uint240 excess);

    /**
     * @notice Emitted when `account` starts being an wM earner.
     * @param  account The account that started earning.
     */
    event StartedEarning(address indexed account);

    /**
     * @notice Emitted when `account` stops being an wM earner.
     * @param  account The account that stopped earning.
     */
    event StoppedEarning(address indexed account);

    /* ============ Custom Errors ============ */

    /// @notice Emitted when performing an operation that is not allowed when earning is disabled.
    error EarningIsDisabled();

    /// @notice Emitted when performing an operation that is not allowed when earning is enabled.
    error EarningIsEnabled();

    /// @notice Emitted when trying to enable earning after it has been explicitly disabled.
    error EarningCannotBeReenabled();

    /// @notice Emitted when calling `stopEarning` for an account approved as earner by TTG.
    error IsApprovedEarner();

    /**
     * @notice Emitted when there is insufficient balance to decrement from `account`.
     * @param  account The account with insufficient balance.
     * @param  balance The balance of the account.
     * @param  amount  The amount to decrement.
     */
    error InsufficientBalance(address account, uint240 balance, uint240 amount);

    /// @notice Emitted when calling `startEarning` for an account not approved as earner by TTG.
    error NotApprovedEarner();

    /// @notice Emitted when the non-governance migrate function is called by a account other than the migration admin.
    error UnauthorizedMigration();

    /// @notice Emitted in constructor if M Token is 0x0.
    error ZeroMToken();

    /// @notice Emitted in constructor if Migration Admin is 0x0.
    error ZeroMigrationAdmin();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Wraps `amount` M from the caller into wM for `recipient`.
     * @param  recipient The account receiving the minted wM.
     * @param  amount    The amount of M deposited.
     * @return wrapped   The amount of wM minted.
     */
    function wrap(address recipient, uint256 amount) external returns (uint240 wrapped);

    /**
     * @notice Wraps all the M from the caller into wM for `recipient`.
     * @param  recipient The account receiving the minted wM.
     * @return wrapped   The amount of wM minted.
     */
    function wrap(address recipient) external returns (uint240 wrapped);

    /**
     * @notice Unwraps `amount` wM from the caller into M for `recipient`.
     * @param  recipient The account receiving the withdrawn M.
     * @param  amount    The amount of wM burned.
     * @return unwrapped The amount of M withdrawn.
     */
    function unwrap(address recipient, uint256 amount) external returns (uint240 unwrapped);

    /**
     * @notice Unwraps all the wM from the caller into M for `recipient`.
     * @param  recipient The account receiving the withdrawn M.
     * @return unwrapped The amount of M withdrawn.
     */
    function unwrap(address recipient) external returns (uint240 unwrapped);

    /**
     * @notice Claims any claimable yield for `account`.
     * @param  account The account under which yield was generated.
     * @return yield   The amount of yield claimed.
     */
    function claimFor(address account) external returns (uint240 yield);

    /**
     * @notice Claims any excess M of the wrapper.
     * @return excess The amount of excess claimed.
     */
    function claimExcess() external returns (uint240 excess);

    /// @notice Enables earning for the wrapper if allowed by TTG and if it has never been done.
    function enableEarning() external;

    /// @notice Disables earning for the wrapper if disallowed by TTG and if it has never been done.
    function disableEarning() external;

    /**
     * @notice Starts earning for `account` if allowed by TTG.
     * @param  account The account to start earning for.
     */
    function startEarningFor(address account) external;

    /**
     * @notice Stops earning for `account` if disallowed by TTG.
     * @param  account The account to stop earning for.
     */
    function stopEarningFor(address account) external;

    /* ============ Temporary Admin Migration ============ */

    /**
     * @notice Performs an arbitrarily defined migration.
     * @param  migrator The address of a migrator contract.
     */
    function migrate(address migrator) external;

    /* ============ View/Pure Functions ============ */

    /**
     * @notice Returns the yield accrued for `account`, which is claimable.
     * @param  account The account being queried.
     * @return yield   The amount of yield that is claimable.
     */
    function accruedYieldOf(address account) external view returns (uint240 yield);

    /**
     * @notice Returns the token balance of `account` including any accrued yield.
     * @param  account The address of some account.
     * @return balance The token balance of `account` including any accrued yield.
     */
    function balanceWithYieldOf(address account) external view returns (uint256 balance);

    /**
     * @notice Returns the last index of `account`.
     * @param  account   The address of some account.
     * @return lastIndex The last index of `account`, 0 if the account is not earning.
     */
    function lastIndexOf(address account) external view returns (uint128 lastIndex);

    /**
     * @notice Returns the recipient to override as the destination for an account's claim of yield.
     * @param  account   The account being queried.
     * @return recipient The address of the recipient, if any, to override as the destination of claimed yield.
     */
    function claimOverrideRecipientFor(address account) external view returns (address recipient);

    /// @notice The current index of the wrapper's earning mechanism.
    function currentIndex() external view returns (uint128 index);

    /// @notice The current excess M of the wrapper that is not earmarked for account balances or accrued yield.
    function excess() external view returns (uint240 excess);

    /**
     * @notice Returns whether `account` is a wM earner.
     * @param  account   The account being queried.
     * @return isEarning true if the account has started earning.
     */
    function isEarning(address account) external view returns (bool isEarning);

    /// @notice Whether earning is enabled for the entire wrapper.
    function isEarningEnabled() external view returns (bool isEnabled);

    /// @notice Whether earning has been enabled at least once or not.
    function wasEarningEnabled() external view returns (bool wasEnabled);

    /// @notice The account that can bypass TTG and call the `migrate(address migrator)` function.
    function migrationAdmin() external view returns (address migrationAdmin);

    /// @notice The address of the M Token contract.
    function mToken() external view returns (address mToken);

    /// @notice The address of the TTG registrar.
    function registrar() external view returns (address registrar);

    /// @notice The portion of total supply that is not earning yield.
    function totalNonEarningSupply() external view returns (uint240 totalSupply);

    /// @notice The accrued yield of the portion of total supply that is earning yield.
    function totalAccruedYield() external view returns (uint240 yield);

    /// @notice The portion of total supply that is earning yield.
    function totalEarningSupply() external view returns (uint240 totalSupply);

    /// @notice The principal of totalEarningSupply to help compute totalAccruedYield(), and thus excess().
    function principalOfTotalEarningSupply() external view returns (uint112 principalOfTotalEarningSupply);

    /// @notice The address of the vault where excess is claimed to.
    function vault() external view returns (address vault);
}

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/StatefulERC712.sol

/**
 * @title  Stateful Extension for EIP-712 typed structured data hashing and signing with nonces.
 * @author M^0 Labs
 * @dev    An abstract implementation to satisfy stateful EIP-712 with nonces.
 */
abstract contract StatefulERC712 is IStatefulERC712, ERC712Extended {
    /// @inheritdoc IStatefulERC712
    mapping(address account => uint256 nonce) public nonces; // Nonces for all signatures.

    /**
     * @notice Construct the StatefulERC712 contract.
     * @param  name_ The name of the contract.
     */
    constructor(string memory name_) ERC712Extended(name_) {}
}

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/ERC3009.sol

/**
 * @title  ERC3009 implementation allowing the transfer of fungible assets via a signed authorization.
 * @author M^0 Labs
 * @dev    Inherits from ERC712 and StatefulERC712.
 */
abstract contract ERC3009 is IERC3009, StatefulERC712 {
    /* ============ Variables ============ */

    // solhint-disable-next-line max-line-length
    /// @dev        keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    /// @inheritdoc IERC3009
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    // solhint-disable-next-line max-line-length
    /// @dev        keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    /// @inheritdoc IERC3009
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    /**
     * @inheritdoc IERC3009
     * @dev        keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
     */
    bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH =
        0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

    /// @inheritdoc IERC3009
    mapping(address authorizer => mapping(bytes32 nonce => bool isNonceUsed)) public authorizationState;

    /* ============ Constructor ============ */

    /**
     * @notice Construct the ERC3009 contract.
     * @param  name_ The name of the contract.
     */
    constructor(string memory name_) StatefulERC712(name_) {}

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IERC3009
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes memory signature_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getTransferWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            signature_
        );

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes32 r_,
        bytes32 vs_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getTransferWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            r_,
            vs_
        );

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getTransferWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            v_,
            r_,
            s_
        );

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes memory signature_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getReceiveWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            signature_
        );

        _receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        bytes32 r_,
        bytes32 vs_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getReceiveWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            r_,
            vs_
        );

        _receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _revertIfInvalidSignature(
            from_,
            _getReceiveWithAuthorizationDigest(from_, to_, value_, validAfter_, validBefore_, nonce_),
            v_,
            r_,
            s_
        );

        _receiveWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /// @inheritdoc IERC3009
    function cancelAuthorization(address authorizer_, bytes32 nonce_, bytes memory signature_) external {
        _revertIfInvalidSignature(authorizer_, _getCancelAuthorizationDigest(authorizer_, nonce_), signature_);
        _cancelAuthorization(authorizer_, nonce_);
    }

    /// @inheritdoc IERC3009
    function cancelAuthorization(address authorizer_, bytes32 nonce_, bytes32 r_, bytes32 vs_) external {
        _revertIfInvalidSignature(authorizer_, _getCancelAuthorizationDigest(authorizer_, nonce_), r_, vs_);
        _cancelAuthorization(authorizer_, nonce_);
    }

    /// @inheritdoc IERC3009
    function cancelAuthorization(address authorizer_, bytes32 nonce_, uint8 v_, bytes32 r_, bytes32 s_) external {
        _revertIfInvalidSignature(authorizer_, _getCancelAuthorizationDigest(authorizer_, nonce_), v_, r_, s_);
        _cancelAuthorization(authorizer_, nonce_);
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Common transfer function used by `transferWithAuthorization` and `_receiveWithAuthorization`.
     * @param from_        Payer's address (Authorizer).
     * @param to_          Payee's address.
     * @param value_       Amount to be transferred.
     * @param validAfter_  The time after which this is valid (unix time).
     * @param validBefore_ The time before which this is valid (unix time).
     * @param nonce_       Unique nonce.
     */
    function _transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal {
        if (block.timestamp <= validAfter_) revert AuthorizationNotYetValid(block.timestamp, validAfter_);
        if (block.timestamp >= validBefore_) revert AuthorizationExpired(block.timestamp, validBefore_);

        _revertIfAuthorizationAlreadyUsed(from_, nonce_);

        authorizationState[from_][nonce_] = true;

        emit AuthorizationUsed(from_, nonce_);

        _transfer(from_, to_, value_);
    }

    /**
     * @dev   Common receive function used by `receiveWithAuthorization`.
     * @param from_        Payer's address (Authorizer).
     * @param to_          Payee's address.
     * @param value_       Amount to be transferred.
     * @param validAfter_  The time after which this is valid (unix time).
     * @param validBefore_ The time before which this is valid (unix time).
     * @param nonce_       Unique nonce.
     */
    function _receiveWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal {
        if (msg.sender != to_) revert CallerMustBePayee(msg.sender, to_);

        _transferWithAuthorization(from_, to_, value_, validAfter_, validBefore_, nonce_);
    }

    /**
     * @dev   Common cancel function used by `cancelAuthorization`.
     * @param authorizer_ Authorizer's address.
     * @param nonce_      Nonce of the authorization.
     */
    function _cancelAuthorization(address authorizer_, bytes32 nonce_) internal {
        _revertIfAuthorizationAlreadyUsed(authorizer_, nonce_);

        authorizationState[authorizer_][nonce_] = true;

        emit AuthorizationCanceled(authorizer_, nonce_);
    }

    /**
     * @dev   Internal ERC20 transfer function that needs to be implemented by the inheriting contract.
     * @param sender_    The sender's address.
     * @param recipient_ The recipient's address.
     * @param amount_    The amount to be transferred.
     */
    function _transfer(address sender_, address recipient_, uint256 amount_) internal virtual;

    /* ============ Internal View/Pure Functions ============ */

    /**
     * @dev    Returns the internal EIP-712 digest of a transferWithAuthorization call.
     * @param  from_        Payer's address (Authorizer).
     * @param  to_          Payee's address.
     * @param  value_       Amount to be transferred.
     * @param  validAfter_  The time after which this is valid (unix time).
     * @param  validBefore_ The time before which this is valid (unix time).
     * @param  nonce_       Unique nonce.
     * @return The internal EIP-712 digest.
     */
    function _getTransferWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal view returns (bytes32) {
        return
            _getDigest(
                keccak256(
                    abi.encode(
                        TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                        from_,
                        to_,
                        value_,
                        validAfter_,
                        validBefore_,
                        nonce_
                    )
                )
            );
    }

    /**
     * @dev    Returns the internal EIP-712 digest of a receiveWithAuthorization call.
     * @param  from_        Payer's address (Authorizer).
     * @param  to_          Payee's address.
     * @param  value_       Amount to be transferred.
     * @param  validAfter_  The time after which this is valid (unix time).
     * @param  validBefore_ The time before which this is valid (unix time).
     * @param  nonce_       Unique nonce.
     * @return The internal EIP-712 digest.
     */
    function _getReceiveWithAuthorizationDigest(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) internal view returns (bytes32) {
        return
            _getDigest(
                keccak256(
                    abi.encode(
                        RECEIVE_WITH_AUTHORIZATION_TYPEHASH,
                        from_,
                        to_,
                        value_,
                        validAfter_,
                        validBefore_,
                        nonce_
                    )
                )
            );
    }

    /**
     * @dev    Returns the internal EIP-712 digest of a cancelAuthorization call.
     * @param  authorizer_ Authorizer's address.
     * @param  nonce_      Nonce of the authorization.
     * @return The internal EIP-712 digest.
     */
    function _getCancelAuthorizationDigest(address authorizer_, bytes32 nonce_) internal view returns (bytes32) {
        return _getDigest(keccak256(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer_, nonce_)));
    }

    /**
     * @dev   Reverts if the authorization is already used.
     * @param authorizer_ The authorizer's address.
     * @param nonce_      The nonce of the authorization.
     */
    function _revertIfAuthorizationAlreadyUsed(address authorizer_, bytes32 nonce_) internal view {
        if (authorizationState[authorizer_][nonce_]) revert AuthorizationAlreadyUsed(authorizer_, nonce_);
    }
}

// test/fuzzing/mocks/wrappedMToken.sol/lib/common/src/ERC20Extended.sol

/**
 * @title  An ERC20 token extended with EIP-2612 permits for signed approvals (via EIP-712 and with EIP-1271
 *         and EIP-5267 compatibility), and extended with EIP-3009 transfer with authorization (via EIP-712).
 * @author M^0 Labs
 */
abstract contract ERC20Extended is IERC20Extended, ERC3009 {
    /* ============ Variables ============ */

    /**
     * @inheritdoc IERC20Extended
     * @dev Keeping this constant, despite `permit` parameter name differences, to ensure max EIP-2612 compatibility.
     *      keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
     */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @inheritdoc IERC20
    uint8 public immutable decimals;

    /// @dev The symbol of the token (stored as a bytes32 instead of a string in order to be immutable).
    bytes32 internal immutable _symbol;

    /// @inheritdoc IERC20
    mapping(address account => mapping(address spender => uint256 allowance)) public allowance;

    /* ============ Constructor ============ */

    /**
     * @notice Constructs the ERC20Extended contract.
     * @param  name_     The name of the token.
     * @param  symbol_   The symbol of the token.
     * @param  decimals_ The number of decimals the token uses.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC3009(name_) {
        _symbol = Bytes32String.toBytes32(symbol_);
        decimals = decimals_;
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IERC20
    function approve(address spender_, uint256 amount_) external returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /// @inheritdoc IERC20Extended
    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external {
        _revertIfInvalidSignature(owner_, _permitAndGetDigest(owner_, spender_, value_, deadline_), v_, r_, s_);
    }

    /// @inheritdoc IERC20Extended
    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        bytes memory signature_
    ) external {
        _revertIfInvalidSignature(owner_, _permitAndGetDigest(owner_, spender_, value_, deadline_), signature_);
    }

    /// @inheritdoc IERC20
    function transfer(address recipient_, uint256 amount_) external returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address sender_, address recipient_, uint256 amount_) external returns (bool success_) {
        uint256 spenderAllowance_ = allowance[sender_][msg.sender]; // Cache `spenderAllowance_` to stack.

        if (spenderAllowance_ != type(uint256).max) {
            if (spenderAllowance_ < amount_) revert InsufficientAllowance(msg.sender, spenderAllowance_, amount_);

            unchecked {
                _setAllowance(sender_, msg.sender, spenderAllowance_ - amount_);
            }
        }

        _transfer(sender_, recipient_, amount_);

        return true;
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IERC20
    function name() external view returns (string memory) {
        return Bytes32String.toString(_name);
    }

    /// @inheritdoc IERC20
    function symbol() external view returns (string memory) {
        return Bytes32String.toString(_symbol);
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev Approve `spender_` to spend `amount_` of tokens from `account_`.
     * @param  account_ The address approving the allowance.
     * @param  spender_ The address approved to spend the tokens.
     * @param  amount_  The amount of tokens being approved for spending.
     */
    function _approve(address account_, address spender_, uint256 amount_) internal virtual {
        _setAllowance(account_, spender_, amount_);
        emit Approval(account_, spender_, amount_);
    }

    /**
     * @dev Set the `amount_` of tokens `spender_` is allowed to spend from `account_`.
     * @param  account_ The address for which the allowance is set.
     * @param  spender_ The address allowed to spend the tokens.
     * @param  amount_  The amount of tokens being allowed for spending.
     */
    function _setAllowance(address account_, address spender_, uint256 amount_) internal virtual {
        allowance[account_][spender_] = amount_;
    }

    /**
     * @dev    Performs the approval based on the permit info, validates the deadline, and returns the digest.
     * @param  owner_    The address of the account approving the allowance.
     * @param  spender_  The address of the account being allowed to spend the tokens.
     * @param  amount_   The amount of tokens being approved for spending.
     * @param  deadline_ The deadline by which the signature must be used.
     * @return digest_   The EIP-712 digest of the permit.
     */
    function _permitAndGetDigest(
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_
    ) internal virtual returns (bytes32 digest_) {
        _revertIfExpired(deadline_);

        _approve(owner_, spender_, amount_);

        unchecked {
            // Nonce realistically cannot overflow.
            return
                _getDigest(
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonces[owner_]++, deadline_))
                );
        }
    }
}

// test/fuzzing/mocks/wrappedMToken.sol/src/WrappedMToken.sol

/*

██╗    ██╗██████╗  █████╗ ██████╗ ██████╗ ███████╗██████╗     ███╗   ███╗    ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
██║    ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗    ████╗ ████║    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
██║ █╗ ██║██████╔╝███████║██████╔╝██████╔╝█████╗  ██║  ██║    ██╔████╔██║       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
██║███╗██║██╔══██╗██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██║  ██║    ██║╚██╔╝██║       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
╚███╔███╔╝██║  ██║██║  ██║██║     ██║     ███████╗██████╔╝    ██║ ╚═╝ ██║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚═════╝     ╚═╝     ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝

*/

/**
 * @title  ERC20 Token contract for wrapping M into a non-rebasing token with claimable yields.
 * @author M^0 Labs
 */
contract WrappedMToken is IWrappedMToken, Migratable, ERC20Extended {
    struct Account {
        bool isEarning;
        uint240 balance;
        uint128 lastIndex;
    }

    /* ============ Variables ============ */

    /// @dev Registrar key holding value of whether the earners list can be ignored or not.
    bytes32 internal constant _EARNERS_LIST_IGNORED = "earners_list_ignored";

    /// @dev Registrar key of earners list.
    bytes32 internal constant _EARNERS_LIST = "earners";

    /// @dev Registrar key prefix to determine the override recipient of an account's accrued yield.
    bytes32 internal constant _CLAIM_OVERRIDE_RECIPIENT_PREFIX = "wm_claim_override_recipient";

    /// @dev Registrar key prefix to determine the migrator contract.
    bytes32 internal constant _MIGRATOR_V1_PREFIX = "wm_migrator_v1";

    /// @inheritdoc IWrappedMToken
    address public immutable migrationAdmin;

    /// @inheritdoc IWrappedMToken
    address public immutable mToken;

    /// @inheritdoc IWrappedMToken
    address public immutable registrar;

    /// @inheritdoc IWrappedMToken
    address public immutable vault;

    /// @inheritdoc IWrappedMToken
    uint112 public principalOfTotalEarningSupply;

    /// @inheritdoc IWrappedMToken
    uint240 public totalEarningSupply;

    /// @inheritdoc IWrappedMToken
    uint240 public totalNonEarningSupply;

    /// @dev Mapping of accounts to their respective `AccountInfo` structs.
    mapping(address account => Account balance) internal _accounts;

    /// @dev Array of indices at which earning was enabled or disabled.
    uint128[] internal _enableDisableEarningIndices;

    /* ============ Constructor ============ */

    /**
     * @dev   Constructs the contract given an M Token address and migration admin.
     *        Note that a proxy will not need to initialize since there are no mutable storage values affected.
     * @param mToken_         The address of an M Token.
     * @param migrationAdmin_ The address of a migration admin.
     */
    constructor(address mToken_, address migrationAdmin_) ERC20Extended("WrappedM by M^0", "wM", 6) {
        if ((mToken = mToken_) == address(0)) revert ZeroMToken();
        if ((migrationAdmin = migrationAdmin_) == address(0)) revert ZeroMigrationAdmin();

        registrar = IMTokenLike(mToken_).ttgRegistrar();
        vault = IRegistrarLike(registrar).vault();
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IWrappedMToken
    function wrap(address recipient_, uint256 amount_) external returns (uint240 wrapped_) {
        return _wrap(msg.sender, recipient_, UIntMath.safe240(amount_));
    }

    /// @inheritdoc IWrappedMToken
    function wrap(address recipient_) external returns (uint240 wrapped_) {
        return _wrap(msg.sender, recipient_, UIntMath.safe240(IMTokenLike(mToken).balanceOf(msg.sender)));
    }

    /// @inheritdoc IWrappedMToken
    function unwrap(address recipient_, uint256 amount_) external returns (uint240 unwrapped_) {
        return _unwrap(msg.sender, recipient_, UIntMath.safe240(amount_));
    }

    /// @inheritdoc IWrappedMToken
    function unwrap(address recipient_) external returns (uint240 unwrapped_) {
        return _unwrap(msg.sender, recipient_, uint240(balanceWithYieldOf(msg.sender)));
    }

    /// @inheritdoc IWrappedMToken
    function claimFor(address account_) external returns (uint240 yield_) {
        return _claim(account_, currentIndex());
    }

    /// @inheritdoc IWrappedMToken
    function claimExcess() external returns (uint240 excess_) {
        emit ExcessClaimed(excess_ = excess());

        IMTokenLike(mToken).transfer(vault, excess_);
    }

    /// @inheritdoc IWrappedMToken
    function enableEarning() external {
        _revertIfNotApprovedEarner(address(this));

        if (isEarningEnabled()) revert EarningIsEnabled();

        // NOTE: This is a temporary measure to prevent re-enabling earning after it has been disabled.
        //       This line will be removed in the future.
        if (wasEarningEnabled()) revert EarningCannotBeReenabled();

        uint128 currentMIndex_ = _currentMIndex();

        _enableDisableEarningIndices.push(currentMIndex_);

        IMTokenLike(mToken).startEarning();

        emit EarningEnabled(currentMIndex_);
    }

    /// @inheritdoc IWrappedMToken
    function disableEarning() external {
        _revertIfApprovedEarner(address(this));

        if (!isEarningEnabled()) revert EarningIsDisabled();

        uint128 currentMIndex_ = _currentMIndex();

        _enableDisableEarningIndices.push(currentMIndex_);

        IMTokenLike(mToken).stopEarning();

        emit EarningDisabled(currentMIndex_);
    }

    /// @inheritdoc IWrappedMToken
    function startEarningFor(address account_) external {
        _revertIfNotApprovedEarner(account_);

        if (!isEarningEnabled()) revert EarningIsDisabled();

        Account storage accountInfo_ = _accounts[account_];

        if (accountInfo_.isEarning) return;

        // NOTE: Use `currentIndex()` if/when upgrading to support `startEarningFor` while earning is disabled.
        uint128 currentIndex_ = _currentMIndex();

        accountInfo_.isEarning = true;
        accountInfo_.lastIndex = currentIndex_;

        uint240 balance_ = accountInfo_.balance;

        _addTotalEarningSupply(balance_, currentIndex_);

        unchecked {
            totalNonEarningSupply -= balance_;
        }

        emit StartedEarning(account_);
    }

    /// @inheritdoc IWrappedMToken
    function stopEarningFor(address account_) external {
        _revertIfApprovedEarner(account_);

        uint128 currentIndex_ = currentIndex();

        _claim(account_, currentIndex_);

        Account storage accountInfo_ = _accounts[account_];

        if (!accountInfo_.isEarning) return;

        accountInfo_.isEarning = false;
        accountInfo_.lastIndex = 0;

        uint240 balance_ = accountInfo_.balance;

        _subtractTotalEarningSupply(balance_, currentIndex_);

        unchecked {
            totalNonEarningSupply += balance_;
        }

        emit StoppedEarning(account_);
    }

    /* ============ Temporary Admin Migration ============ */

    /// @inheritdoc IWrappedMToken
    function migrate(address migrator_) external {
        if (msg.sender != migrationAdmin) revert UnauthorizedMigration();

        _migrate(migrator_);
    }

    /* ============ View/Pure Functions ============ */

    /// @inheritdoc IWrappedMToken
    function accruedYieldOf(address account_) public view returns (uint240 yield_) {
        Account storage accountInfo_ = _accounts[account_];

        if (!accountInfo_.isEarning) return 0;

        return _getAccruedYield(accountInfo_.balance, accountInfo_.lastIndex, currentIndex());
    }

    /// @inheritdoc IERC20
    function balanceOf(address account_) public view returns (uint256 balance_) {
        return _accounts[account_].balance;
    }

    /// @inheritdoc IWrappedMToken
    function balanceWithYieldOf(address account_) public view returns (uint256 balance_) {
        return balanceOf(account_) + accruedYieldOf(account_);
    }

    /// @inheritdoc IWrappedMToken
    function lastIndexOf(address account_) public view returns (uint128 lastIndex_) {
        return _accounts[account_].lastIndex;
    }

    /// @inheritdoc IWrappedMToken
    function claimOverrideRecipientFor(address account_) public view returns (address recipient_) {
        return
            address(
                uint160(
                    uint256(
                        IRegistrarLike(registrar).get(keccak256(abi.encode(_CLAIM_OVERRIDE_RECIPIENT_PREFIX, account_)))
                    )
                )
            );
    }

    /// @inheritdoc IWrappedMToken
    function currentIndex() public view returns (uint128 index_) {
        return isEarningEnabled() ? _currentMIndex() : _lastDisableEarningIndex();
    }

    /// @inheritdoc IWrappedMToken
    function isEarning(address account_) external view returns (bool isEarning_) {
        return _accounts[account_].isEarning;
    }

    /// @inheritdoc IWrappedMToken
    function isEarningEnabled() public view returns (bool isEnabled_) {
        return _enableDisableEarningIndices.length % 2 == 1;
    }

    /// @inheritdoc IWrappedMToken
    function wasEarningEnabled() public view returns (bool wasEarning_) {
        return _enableDisableEarningIndices.length != 0;
    }

    /// @inheritdoc IWrappedMToken
    function excess() public view returns (uint240 excess_) {
        unchecked {
            uint128 currentIndex_ = currentIndex();
            uint240 balance_ = uint240(IMTokenLike(mToken).balanceOf(address(this)));
            uint240 earmarked_ = totalNonEarningSupply + _projectedEarningSupply(currentIndex_);

            return balance_ > earmarked_ ? _getSafeTransferableM(balance_ - earmarked_, currentIndex_) : 0;
        }
    }

    /// @inheritdoc IWrappedMToken
    function totalAccruedYield() external view returns (uint240 yield_) {
        uint240 projectedEarningSupply_ = _projectedEarningSupply(currentIndex());
        uint240 earningSupply_ = totalEarningSupply;

        unchecked {
            return projectedEarningSupply_ <= earningSupply_ ? 0 : projectedEarningSupply_ - earningSupply_;
        }
    }

    /// @inheritdoc IERC20
    function totalSupply() external view returns (uint256 totalSupply_) {
        return totalEarningSupply + totalNonEarningSupply;
    }

    /* ============ Internal Interactive Functions ============ */

    /**
     * @dev   Mints `amount_` tokens to `recipient_`.
     * @param recipient_ The address whose account balance will be incremented.
     * @param amount_    The present amount of tokens to mint.
     */
    function _mint(address recipient_, uint240 amount_) internal {
        _revertIfInsufficientAmount(amount_);
        _revertIfInvalidRecipient(recipient_);

        if (_accounts[recipient_].isEarning) {
            uint128 currentIndex_ = currentIndex();

            _claim(recipient_, currentIndex_);

            // NOTE: Additional principal may end up being rounded to 0 and this will not `_revertIfInsufficientAmount`.
            _addEarningAmount(recipient_, amount_, currentIndex_);
        } else {
            _addNonEarningAmount(recipient_, amount_);
        }

        emit Transfer(address(0), recipient_, amount_);
    }

    /**
     * @dev   Burns `amount_` tokens from `account_`.
     * @param account_ The address whose account balance will be decremented.
     * @param amount_  The present amount of tokens to burn.
     */
    function _burn(address account_, uint240 amount_) internal {
        _revertIfInsufficientAmount(amount_);

        if (_accounts[account_].isEarning) {
            uint128 currentIndex_ = currentIndex();

            _claim(account_, currentIndex_);

            // NOTE: Subtracted principal may end up being rounded to 0 and this will not `_revertIfInsufficientAmount`.
            _subtractEarningAmount(account_, amount_, currentIndex_);
        } else {
            _subtractNonEarningAmount(account_, amount_);
        }

        emit Transfer(account_, address(0), amount_);
    }

    /**
     * @dev   Increments the token balance of `account_` by `amount_`, assuming non-earning status.
     * @param account_ The address whose account balance will be incremented.
     * @param amount_  The present amount of tokens to increment by.
     */
    function _addNonEarningAmount(address account_, uint240 amount_) internal {
        // NOTE: Can be `unchecked` because the max amount of wrappable M is never greater than `type(uint240).max`.
        unchecked {
            _accounts[account_].balance += amount_;
            totalNonEarningSupply += amount_;
        }
    }

    /**
     * @dev   Decrements the token balance of `account_` by `amount_`, assuming non-earning status.
     * @param account_ The address whose account balance will be decremented.
     * @param amount_  The present amount of tokens to decrement by.
     */
    function _subtractNonEarningAmount(address account_, uint240 amount_) internal {
        unchecked {
            Account storage accountInfo_ = _accounts[account_];

            uint240 balance_ = accountInfo_.balance;

            if (balance_ < amount_) revert InsufficientBalance(account_, balance_, amount_);

            accountInfo_.balance = balance_ - amount_;
            totalNonEarningSupply -= amount_;
        }
    }

    /**
     * @dev   Increments the token balance of `account_` by `amount_`, assuming earning status and updated index.
     * @param account_      The address whose account balance will be incremented.
     * @param amount_       The present amount of tokens to increment by.
     * @param currentIndex_ The current index to use to compute the principal amount.
     */
    function _addEarningAmount(address account_, uint240 amount_, uint128 currentIndex_) internal {
        // NOTE: Can be `unchecked` because the max amount of wrappable M is never greater than `type(uint240).max`.
        unchecked {
            _accounts[account_].balance += amount_;
            _addTotalEarningSupply(amount_, currentIndex_);
        }
    }

    /**
     * @dev   Decrements the token balance of `account_` by `amount_`, assuming earning status and updated index.
     * @param account_      The address whose account balance will be decremented.
     * @param amount_       The present amount of tokens to decrement by.
     * @param currentIndex_ The current index to use to compute the principal amount.
     */
    function _subtractEarningAmount(address account_, uint240 amount_, uint128 currentIndex_) internal {
        unchecked {
            Account storage accountInfo_ = _accounts[account_];

            uint240 balance_ = accountInfo_.balance;

            if (balance_ < amount_) revert InsufficientBalance(account_, balance_, amount_);

            accountInfo_.balance = balance_ - amount_;
            _subtractTotalEarningSupply(amount_, currentIndex_);
        }
    }

    /**
     * @dev    Claims accrued yield for `account_` given a `currentIndex_`.
     * @param  account_      The address to claim accrued yield for.
     * @param  currentIndex_ The current index to accrue until.
     * @return yield_        The accrued yield that was claimed.
     */
    function _claim(address account_, uint128 currentIndex_) internal returns (uint240 yield_) {
        Account storage accountInfo_ = _accounts[account_];

        if (!accountInfo_.isEarning) return 0;

        uint128 index_ = accountInfo_.lastIndex;

        if (currentIndex_ == index_) return 0;

        uint240 startingBalance_ = accountInfo_.balance;

        yield_ = _getAccruedYield(startingBalance_, index_, currentIndex_);

        accountInfo_.lastIndex = currentIndex_;

        unchecked {
            if (yield_ == 0) return 0;

            accountInfo_.balance = startingBalance_ + yield_;

            // Update the total earning supply to account for the yield, but the principal has not changed.
            totalEarningSupply += yield_;
        }

        address claimOverrideRecipient_ = claimOverrideRecipientFor(account_);
        address claimRecipient_ = claimOverrideRecipient_ == address(0) ? account_ : claimOverrideRecipient_;

        // Emit the appropriate `Claimed` and `Transfer` events, depending on the claim override recipient
        emit Claimed(account_, claimRecipient_, yield_);
        emit Transfer(address(0), account_, yield_);

        if (claimRecipient_ != account_) {
            // NOTE: Watch out for a long chain of earning claim override recipients.
            _transfer(account_, claimRecipient_, yield_, currentIndex_);
        }
    }

    /**
     * @dev   Transfers `amount_` tokens from `sender_` to `recipient_` given some current index.
     * @param sender_       The sender's address.
     * @param recipient_    The recipient's address.
     * @param amount_       The amount to be transferred.
     * @param currentIndex_ The current index.
     */
    function _transfer(address sender_, address recipient_, uint240 amount_, uint128 currentIndex_) internal {
        _revertIfInvalidRecipient(recipient_);

        // Claims for both the sender and recipient are required before transferring since add an subtract functions
        // assume accounts' balances are up-to-date with the current index.
        _claim(sender_, currentIndex_);
        _claim(recipient_, currentIndex_);

        emit Transfer(sender_, recipient_, amount_);

        Account storage senderAccountInfo_ = _accounts[sender_];
        Account storage recipientAccountInfo_ = _accounts[recipient_];

        // If the sender and recipient are both earning or both non-earning, update their balances without affecting
        // the total earning and non-earning supply storage variables.
        if (senderAccountInfo_.isEarning == recipientAccountInfo_.isEarning) {
            uint240 senderBalance_ = senderAccountInfo_.balance;

            if (senderBalance_ < amount_) revert InsufficientBalance(sender_, senderBalance_, amount_);

            unchecked {
                senderAccountInfo_.balance = senderBalance_ - amount_;
                recipientAccountInfo_.balance += amount_;
            }

            return;
        }

        senderAccountInfo_.isEarning
            ? _subtractEarningAmount(sender_, amount_, currentIndex_)
            : _subtractNonEarningAmount(sender_, amount_);

        recipientAccountInfo_.isEarning
            ? _addEarningAmount(recipient_, amount_, currentIndex_)
            : _addNonEarningAmount(recipient_, amount_);
    }

    /**
     * @dev   Internal ERC20 transfer function that needs to be implemented by the inheriting contract.
     * @param sender_    The sender's address.
     * @param recipient_ The recipient's address.
     * @param amount_    The amount to be transferred.
     */
    function _transfer(address sender_, address recipient_, uint256 amount_) internal override {
        _transfer(sender_, recipient_, UIntMath.safe240(amount_), currentIndex());
    }

    /**
     * @dev   Increments total earning supply by `amount_` tokens.
     * @param amount_       The present amount of tokens to increment total earning supply by.
     * @param currentIndex_ The current index used to compute the principal amount.
     */
    function _addTotalEarningSupply(uint240 amount_, uint128 currentIndex_) internal {
        unchecked {
            // Increment the total earning supply and principal proportionally.
            totalEarningSupply += amount_;
            principalOfTotalEarningSupply += IndexingMath.getPrincipalAmountRoundedUp(amount_, currentIndex_);
        }
    }

    /**
     * @dev   Decrements total earning supply by `amount_` tokens.
     * @param amount_       The present amount of tokens to decrement total earning supply by.
     * @param currentIndex_ The current index used to compute the principal amount.
     */
    function _subtractTotalEarningSupply(uint240 amount_, uint128 currentIndex_) internal {
        if (amount_ >= totalEarningSupply) {
            totalEarningSupply = 0;
            principalOfTotalEarningSupply = 0;

            return;
        }

        unchecked {
            uint112 principal_ = IndexingMath.getPrincipalAmountRoundedDown(amount_, currentIndex_);

            principalOfTotalEarningSupply -= (
                principal_ > principalOfTotalEarningSupply ? principalOfTotalEarningSupply : principal_
            );

            totalEarningSupply -= amount_;
        }
    }

    /**
     * @dev    Wraps `amount` M from `account_` into wM for `recipient`.
     * @param  account_   The account from which M is deposited.
     * @param  recipient_ The account receiving the minted wM.
     * @param  amount_    The amount of M deposited.
     * @return wrapped_   The amount of wM minted.
     */
    function _wrap(address account_, address recipient_, uint240 amount_) internal returns (uint240 wrapped_) {
        uint256 startingBalance_ = IMTokenLike(mToken).balanceOf(address(this));

        // NOTE: The behavior of `IMTokenLike.transferFrom` is known, so its return can be ignored.
        IMTokenLike(mToken).transferFrom(account_, address(this), amount_);

        // NOTE: When this WrappedMToken contract is earning, any amount of M sent to it is converted to a principal
        //       amount at the MToken contract, which when represented as a present amount, may be a rounding error
        //       amount less than `amount_`. In order to capture the real increase in M, the difference between the
        //       starting and ending M balance is minted as WrappedM.
        _mint(recipient_, wrapped_ = UIntMath.safe240(IMTokenLike(mToken).balanceOf(address(this)) - startingBalance_));
    }

    /**
     * @dev    Unwraps `amount` wM from `account_` into M for `recipient`.
     * @param  account_   The account from which WM is burned.
     * @param  recipient_ The account receiving the withdrawn M.
     * @param  amount_    The amount of wM burned.
     * @return unwrapped_ The amount of M withdrawn.
     */
    function _unwrap(address account_, address recipient_, uint240 amount_) internal returns (uint240 unwrapped_) {
        _burn(account_, amount_);

        uint256 startingBalance_ = IMTokenLike(mToken).balanceOf(address(this));

        // NOTE: The behavior of `IMTokenLike.transfer` is known, so its return can be ignored.
        IMTokenLike(mToken).transfer(recipient_, _getSafeTransferableM(amount_, currentIndex()));

        // NOTE: When this WrappedMToken contract is earning, any amount of M sent from it is converted to a principal
        //       amount at the MToken contract, which when represented as a present amount, may be a rounding error
        //       amount more than `amount_`. In order to capture the real decrease in M, the difference between the
        //       ending and starting M balance is returned.
        return UIntMath.safe240(startingBalance_ - IMTokenLike(mToken).balanceOf(address(this)));
    }

    /* ============ Internal View/Pure Functions ============ */

    /// @dev Returns the current index of the M Token.
    function _currentMIndex() internal view returns (uint128 index_) {
        return IMTokenLike(mToken).currentIndex();
    }

    /// @dev Returns the earning index from the last `disableEarning` call.
    function _lastDisableEarningIndex() internal view returns (uint128 index_) {
        return wasEarningEnabled() ? _unsafeAccess(_enableDisableEarningIndices, 1) : 0;
    }

    /**
     * @dev    Compute the yield given an account's balance, last index, and the current index.
     * @param  balance_      The token balance of an earning account.
     * @param  lastIndex_    The index of ast interaction for the account.
     * @param  currentIndex_ The current index.
     * @return yield_        The yield accrued since the last interaction.
     */
    function _getAccruedYield(
        uint240 balance_,
        uint128 lastIndex_,
        uint128 currentIndex_
    ) internal pure returns (uint240 yield_) {
        uint240 balanceWithYield_ = IndexingMath.getPresentAmountRoundedDown(
            IndexingMath.getPrincipalAmountRoundedDown(balance_, lastIndex_),
            currentIndex_
        );

        unchecked {
            return (balanceWithYield_ <= balance_) ? 0 : balanceWithYield_ - balance_;
        }
    }

    /**
     * @dev    Compute the adjusted amount of M that can safely be transferred out given the current index.
     * @param  amount_       Some amount to be transferred out of the wrapper.
     * @param  currentIndex_ The current index.
     * @return safeAmount_   The adjusted amount that can safely be transferred out.
     */
    function _getSafeTransferableM(uint240 amount_, uint128 currentIndex_) internal view returns (uint240 safeAmount_) {
        // If the wrapper is earning, adjust `amount_` to ensure it's M balance decrement is limited to `amount_`.
        return
            IMTokenLike(mToken).isEarning(address(this))
                ? IndexingMath.getPresentAmountRoundedDown(
                    IndexingMath.getPrincipalAmountRoundedDown(amount_, currentIndex_),
                    currentIndex_
                )
                : amount_;
    }

    /// @dev Returns the address of the contract to use as a migrator, if any.
    function _getMigrator() internal view override returns (address migrator_) {
        return
            address(
                uint160(
                    // NOTE: A subsequent implementation should use a unique migrator prefix.
                    uint256(IRegistrarLike(registrar).get(keccak256(abi.encode(_MIGRATOR_V1_PREFIX, address(this)))))
                )
            );
    }

    /**
     * @dev    Returns whether `account_` is a TTG-approved earner.
     * @param  account_    The account being queried.
     * @return isApproved_ True if the account_ is a TTG-approved earner, false otherwise.
     */
    function _isApprovedEarner(address account_) internal view returns (bool isApproved_) {
        return
            IRegistrarLike(registrar).get(_EARNERS_LIST_IGNORED) != bytes32(0) ||
            IRegistrarLike(registrar).listContains(_EARNERS_LIST, account_);
    }

    /**
     * @dev    Returns the projected total earning supply if all accrued yield was claimed at this moment.
     * @param  currentIndex_ The current index.
     * @return supply_       The projected total earning supply.
     */
    function _projectedEarningSupply(uint128 currentIndex_) internal view returns (uint240 supply_) {
        return IndexingMath.getPresentAmountRoundedDown(principalOfTotalEarningSupply, currentIndex_);
    }

    /**
     * @dev   Reverts if `amount_` is equal to 0.
     * @param amount_ Amount of token.
     */
    function _revertIfInsufficientAmount(uint256 amount_) internal pure {
        if (amount_ == 0) revert InsufficientAmount(amount_);
    }

    /**
     * @dev   Reverts if `recipient_` is address(0).
     * @param recipient_ Address of a recipient.
     */
    function _revertIfInvalidRecipient(address recipient_) internal pure {
        if (recipient_ == address(0)) revert InvalidRecipient(recipient_);
    }

    /**
     * @dev   Reverts if `account_` is an approved earner.
     * @param account_ Address of an account.
     */
    function _revertIfApprovedEarner(address account_) internal view {
        if (_isApprovedEarner(account_)) revert IsApprovedEarner();
    }

    /**
     * @dev   Reverts if `account_` is not an approved earner.
     * @param account_ Address of an account.
     */
    function _revertIfNotApprovedEarner(address account_) internal view {
        if (!_isApprovedEarner(account_)) revert NotApprovedEarner();
    }

    /**
     * @dev   Reads the uint128 value at some index of an array of uint128 values whose storage pointer is given,
     *        assuming the index is valid, without wasting gas checking for out-of-bounds errors.
     * @param array_ The storage pointer of an array of uint128 values.
     * @param i_     The index of the array to read.
     */
    function _unsafeAccess(uint128[] storage array_, uint256 i_) internal view returns (uint128 value_) {
        assembly {
            mstore(0, array_.slot)

            value_ := sload(add(keccak256(0, 0x20), div(i_, 2)))

            // Since uint128 values take up either the top half or bottom half of a slot, shift the result accordingly.
            if eq(mod(i_, 2), 1) {
                value_ := shr(128, value_)
            }
        }
    }
}
