// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { ContinuousIndexingMath } from "../../lib/common/src/libs/ContinuousIndexingMath.sol";

import { IMExtension } from "../../src/interfaces/IMExtension.sol";
import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";
import { IRegistrarLike } from "../../src/interfaces/IRegistrarLike.sol";

import { MYieldToOne } from "../../src/MYieldToOne.sol";
import { MYieldFee } from "../../src/MYieldFee.sol";
import { MEarnerManager } from "../../src/MEarnerManager.sol";

import { Helpers } from "./Helpers.sol";

contract BaseIntegrationTest is Helpers, Test {
    address public constant standardGovernor = 0xB024aC5a7c6bC92fbACc8C3387E628a07e1Da016;
    address public constant registrar = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;

    IMTokenLike public constant mToken = IMTokenLike(0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b);

    uint16 public constant YIELD_FEE_RATE = 2000; // 20%

    bytes32 internal constant EARNERS_LIST = "earners";
    uint32 public constant M_EARNER_RATE = ContinuousIndexingMath.BPS_SCALED_ONE / 10; // 10% APY

    uint56 public constant EXP_SCALED_ONE = 1e12;

    // Large M holder on Ethereum Mainnet
    address public constant mSource = 0x3f0376da3Ae4313E7a5F1dA184BAFC716252d759;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant YIELD_FEE_MANAGER_ROLE = keccak256("YIELD_FEE_MANAGER_ROLE");
    bytes32 public constant YIELD_RECIPIENT_MANAGER_ROLE = keccak256("YIELD_RECIPIENT_MANAGER_ROLE");
    bytes32 public constant EARNER_MANAGER_ROLE = keccak256("EARNER_MANAGER_ROLE");

    address public admin = makeAddr("admin");
    address public blacklistManager = makeAddr("blacklistManager");
    address public yieldRecipient = makeAddr("yieldRecipient");
    address public yieldRecipientManager = makeAddr("yieldRecipientManager");
    address public yieldFeeRecipient = makeAddr("yieldFeeRecipient");
    address public yieldFeeManager = makeAddr("yieldFeeManager");
    address public claimRecipientManager = makeAddr("claimRecipientManager");
    address public earnerManager = makeAddr("earnerManager");
    address public feeRecipient = makeAddr("feeRecipient");

    address public alice;
    uint256 public aliceKey;

    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public charlie = makeAddr("charlie");
    address public david = makeAddr("david");

    address[] public accounts = [alice, bob, carol, charlie, david];

    MYieldToOne public mYieldToOne;
    MYieldFee public mYieldFee;
    MEarnerManager public mEarnerManager;

    string public constant NAME = "M USD Extension";
    string public constant SYMBOL = "MUSDE";

    function setUp() public virtual {
        (alice, aliceKey) = makeAddrAndKey("alice");
        accounts = [alice, bob, carol, charlie, david];
    }

    function _addToList(bytes32 list, address account) internal {
        vm.prank(standardGovernor);
        IRegistrarLike(registrar).addToList(list, account);
    }

    function _removeFomList(bytes32 list, address account) internal {
        vm.prank(standardGovernor);
        IRegistrarLike(registrar).removeFromList(list, account);
    }

    function _giveM(address account, uint256 amount) internal {
        vm.prank(mSource);
        mToken.transfer(account, amount);
    }

    function _giveEth(address account, uint256 amount) internal {
        vm.deal(account, amount);
    }

    function _wrap(address mExtension, address account, address recipient, uint256 amount) internal {
        vm.prank(account);
        mToken.approve(address(mExtension), amount);

        vm.prank(account);
        IMExtension(mExtension).wrap(recipient, amount);
    }

    function _wrapWithPermitVRS(
        address mExtension,
        address account,
        uint256 signerPrivateKey,
        address recipient,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) internal {
        (uint8 v_, bytes32 r_, bytes32 s_) = _getPermit(mExtension, account, signerPrivateKey, amount, nonce, deadline);

        vm.prank(account);
        IMExtension(mExtension).wrapWithPermit(recipient, amount, deadline, v_, r_, s_);
    }

    function _unwrap(address mExtension, address account, address recipient, uint256 amount) internal {
        vm.prank(account);
        IMExtension(mExtension).unwrap(recipient, amount);
    }

    function _set(bytes32 key, bytes32 value) internal {
        vm.prank(standardGovernor);
        IRegistrarLike(registrar).setKey(key, value);
    }

    function _fundAccounts() internal {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _giveM(accounts[i], 10e6);
            _giveEth(accounts[i], 0.1 ether);
        }
    }

    /* ============ utils ============ */

    function _makeKey(string memory name_) internal returns (uint256 key_) {
        (, key_) = makeAddrAndKey(name_);
    }

    function _getPermit(
        address mExtension,
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
                        mToken.DOMAIN_SEPARATOR(),
                        keccak256(abi.encode(mToken.PERMIT_TYPEHASH(), account, mExtension, amount, nonce, deadline))
                    )
                )
            );
    }
}
