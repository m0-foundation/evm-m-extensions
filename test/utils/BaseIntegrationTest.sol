// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { IRegistrarLike } from "../../src/interfaces/IRegistrarLike.sol";
import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";

import { MYieldToOne } from "../../src/MYieldToOne.sol";

contract BaseIntegrationTest is Test {
    address internal constant _standardGovernor = 0xB024aC5a7c6bC92fbACc8C3387E628a07e1Da016;
    address internal constant _registrar = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;

    bytes32 internal constant _EARNERS_LIST = "earners";
    bytes32 internal constant _CLAIM_OVERRIDE_recipientPREFIX = "wm_claim_override_recipient";

    IMTokenLike internal constant _mToken = IMTokenLike(0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b);

    // Large M holder on Ethereum Mainnet
    address internal constant _mSource = 0x3f0376da3Ae4313E7a5F1dA184BAFC716252d759;

    address internal _yieldRecipient = makeAddr("yieldRecipient");

    address internal _alice = makeAddr("alice");
    address internal _bob = makeAddr("bob");
    address internal _carol = makeAddr("carol");

    uint256 internal _aliceKey = _makeKey("alice");

    address[] internal _accounts = [_alice, _bob, _carol];

    MYieldToOne internal _mYieldToOne;

    function _addToList(bytes32 list, address account) internal {
        vm.prank(_standardGovernor);
        IRegistrarLike(_registrar).addToList(list, account);
    }

    function _removeFomList(bytes32 list, address account) internal {
        vm.prank(_standardGovernor);
        IRegistrarLike(_registrar).removeFromList(list, account);
    }

    function _giveM(address account, uint256 amount) internal {
        vm.prank(_mSource);
        _mToken.transfer(account, amount);
    }

    function _giveEth(address account, uint256 amount) internal {
        vm.deal(account, amount);
    }

    function _wrap(address account, address recipient, uint256 amount) internal {
        vm.prank(account);
        _mToken.approve(address(_mYieldToOne), amount);

        vm.prank(account);
        _mYieldToOne.wrap(recipient, amount);
    }

    function _wrapWithPermitVRS(
        address account,
        uint256 signerPrivateKey,
        address recipient,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) internal {
        (uint8 v_, bytes32 r_, bytes32 s_) = _getPermit(account, signerPrivateKey, amount, nonce, deadline);

        vm.prank(account);
        _mYieldToOne.wrapWithPermit(recipient, amount, deadline, v_, r_, s_);
    }

    function _unwrap(address account, address recipient, uint256 amount) internal {
        vm.prank(account);
        _mYieldToOne.unwrap(recipient, amount);
    }

    function _set(bytes32 key, bytes32 value) internal {
        vm.prank(_standardGovernor);
        IRegistrarLike(_registrar).setKey(key, value);
    }

    function _fundAccounts() internal {
        for (uint256 i = 0; i < _accounts.length; ++i) {
            _giveM(_accounts[i], 10e6);
            _giveEth(_accounts[i], 0.1 ether);
        }
    }

    /* ============ utils ============ */

    function _makeKey(string memory name_) internal returns (uint256 key_) {
        (, key_) = makeAddrAndKey(name_);
    }

    function _getPermit(
        address account,
        uint256 signerPrivateKey,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (uint8 v_, bytes32 r_, bytes32 s_) {
        return
            vm.sign(
                signerPrivateKey,
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        _mToken.DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                _mToken.PERMIT_TYPEHASH(),
                                account,
                                address(_mYieldToOne),
                                amount,
                                nonce,
                                deadline
                            )
                        )
                    )
                )
            );
    }
}
