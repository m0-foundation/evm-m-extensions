// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IMExtension } from "../../src/interfaces/IMExtension.sol";
import { ISwapFacility } from "../../src/interfaces/ISwapFacility.sol";
import { IRegistrarLike } from "../../src/interfaces/IRegistrarLike.sol";
import { SwapFacility } from "../../src/SwapFacility.sol";

import { MockM, MockMExtension, MockRegistrar } from "../utils/Mocks.sol";

contract SwapFacilityUnitTests is Test {
    SwapFacility public swapFacility;

    MockM public mToken;
    MockRegistrar public registrar;
    MockMExtension public extensionA;
    MockMExtension public extensionB;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    function setUp() public {
        mToken = new MockM();
        registrar = new MockRegistrar();

        address implementation = address(new SwapFacility(address(mToken), address(registrar)));
        ERC1967Proxy proxy = new ERC1967Proxy(
            implementation,
            abi.encodeWithSelector(SwapFacility.initialize.selector, owner)
        );
        swapFacility = SwapFacility(address(proxy));

        extensionA = new MockMExtension(address(mToken), address(swapFacility));
        extensionB = new MockMExtension(address(mToken), address(swapFacility));

        // Add Extensions to Earners List
        registrar.setEarner(address(extensionA), true);
        registrar.setEarner(address(extensionB), true);
    }

    function test_initialState() external {
        assertEq(swapFacility.mToken(), address(mToken));
        assertEq(swapFacility.registrar(), address(registrar));
        assertEq(swapFacility.owner(), owner);
    }

    function test_constructor_zeroMToken() external {
        vm.expectRevert(ISwapFacility.ZeroMToken.selector);
        new SwapFacility(address(0), address(registrar));
    }

    function test_constructor_zeroRegistrar() external {
        vm.expectRevert(ISwapFacility.ZeroRegistrar.selector);
        new SwapFacility(address(mToken), address(0));
    }

    function test_swapM() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.expectEmit(true, true, true, true);
        emit ISwapFacility.SwappedM(address(extensionA), amount, alice);

        vm.prank(alice);
        swapFacility.swapM(address(extensionA), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), amount);
    }

    function test_swapM_zeroAmount() external {
        vm.expectRevert(ISwapFacility.ZeroAmount.selector);
        swapFacility.swapM(address(extensionA), 0, alice);
    }

    function test_swapM_zeroRecipient() external {
        vm.expectRevert(ISwapFacility.ZeroRecipient.selector);
        swapFacility.swapM(address(extensionA), 1_000, address(0));
    }

    function test_swapM_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swapM(address(0x123), 1, address(this));
    }

    function test_swap() external {
        uint256 amount = 1_000;
        mToken.setBalanceOf(alice, amount);

        vm.startPrank(alice);
        extensionA.wrap(alice, amount);
        extensionA.approve(address(swapFacility), amount);

        vm.expectEmit(true, true, true, true);
        emit ISwapFacility.Swapped(address(extensionA), address(extensionB), amount, alice);

        swapFacility.swap(address(extensionA), address(extensionB), amount, alice);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(extensionA.balanceOf(alice), 0);
        assertEq(extensionB.balanceOf(alice), amount);
    }

    function test_swap_zeroAmount() external {
        vm.expectRevert(ISwapFacility.ZeroAmount.selector);
        swapFacility.swap(address(extensionA), address(extensionB), 0, alice);
    }

    function test_swap_zeroRecipient() external {
        vm.expectRevert(ISwapFacility.ZeroRecipient.selector);
        swapFacility.swap(address(extensionA), address(extensionB), 1_000, address(0));
    }

    function test_swap_notApprovedExtension() external {
        address notApprovedExtension = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swap(address(0x123), address(extensionA), 1_000, address(this));

        vm.expectRevert(abi.encodeWithSelector(ISwapFacility.NotApprovedExtension.selector, notApprovedExtension));
        swapFacility.swap(address(extensionB), address(0x123), 1_000, address(this));
    }
}
