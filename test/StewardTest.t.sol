// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {BoringAddress} from "@boring/libraries/BoringAddress.sol";

import {Unauthorized} from "@omniprotocol/mixins/auth/Auth.sol";
import {ChainEnvironmentTest, Steward} from "./ChainEnvironmentTest.t.sol";

contract StewardTest is ChainEnvironmentTest {
    function testFailAlreadyInitialized() public {
        steward.initialize(beneficiary, abi.encodePacked(address(this)));
    }

    function testCloneGas() public {
        Steward c = Steward(payable(factory.createSteward(address(this))));
        assertEq(c.owner(), address(this));
    }

    function testMulticallable() public {
        bytes[] memory functions = new bytes[](4);
        functions[0] = abi.encodeWithSignature(
            "setRoleCapability(uint8,bytes4,bool)",
            0,
            erc20note.mint.selector,
            true
        );
        functions[1] = abi.encodeWithSignature(
            "setUserRole(address,uint8,bool)",
            address(this),
            0,
            true
        );
        functions[2] = abi.encodeWithSignature(
            "doesUserHaveRole(address,uint8)",
            address(this),
            0
        );
        functions[3] = abi.encodeWithSignature(
            "doesRoleHaveCapability(uint8,bytes4)",
            0,
            erc20note.mint.selector
        );
        bytes[] memory results = steward.multicall(functions);
        assertTrue(abi.decode(results[2], (bool)));
        assertTrue(abi.decode(results[3], (bool)));
    }

    function testOwner() public {
        assertEq(steward.owner(), address(this));
    }

    function testSetOwner() public {
        steward.setOwner(beneficiary);
        assertEq(steward.owner(), beneficiary);
    }

    function testAuthority() public {
        assertEq(address(steward.authority()), address(steward));
    }

    function stewardTransfer(uint256 amount) internal {
        vm.assume(amount < address(this).balance);
        payable(address(steward)).transfer(amount);
    }

    function testWithdrawTo(address receiver, uint256 amount) public {
        vm.assume(
            !BoringAddress.isContract(receiver) && receiver != address(this)
        );
        stewardTransfer(amount);
        steward.withdrawTo(receiver, amount);
        assertEq(receiver.balance, amount);
    }

    function testWithdrawToRequiresAuth(address caller, uint256 amount) public {
        vm.assume(
            caller != address(this) &&
                !steward.canCall(
                    caller,
                    address(steward),
                    steward.withdrawTo.selector
                )
        );

        stewardTransfer(amount);
        vm.expectRevert(Unauthorized.selector);
        vm.prank(caller);
        steward.withdrawTo(caller, amount);
    }
}
