// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { MockM, MockRegistrar } from "../utils/Mocks.sol";

contract BaseUnitTest is Test {
    uint16 public constant HUNDRED_PERCENT = 10_000;
    uint16 public constant YIELD_FEE_RATE = 2000; // 20%

    bytes32 public constant EARNERS_LIST = "earners";
    uint56 public constant EXP_SCALED_ONE = 1e12;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant YIELD_FEE_MANAGER_ROLE = keccak256("YIELD_FEE_MANAGER_ROLE");

    MockM public mToken;
    MockRegistrar public registrar;

    address public admin = makeAddr("admin");
    address public blacklistManager = makeAddr("blacklistManager");
    address public yieldRecipient = makeAddr("yieldRecipient");
    address public yieldFeeRecipient = makeAddr("yieldFeeRecipient");
    address public yieldFeeManager = makeAddr("yieldFeeManager");

    address public alice;
    uint256 public aliceKey;

    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public charlie = makeAddr("charlie");
    address public david = makeAddr("david");

    address[] public accounts;

    function setUp() public virtual {
        mToken = new MockM();
        registrar = new MockRegistrar();

        (alice, aliceKey) = makeAddrAndKey("alice");
        accounts = [alice, bob, charlie, david];
    }
}
