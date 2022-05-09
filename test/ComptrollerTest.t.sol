// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {BoringAddress} from "@boring/libraries/BoringAddress.sol";

import {ChainEnvironmentTest, Comptroller} from "@test/ChainEnvironmentTest.t.sol";

contract ComptrollerTest is ChainEnvironmentTest {
  function testCloneGas() public {
    Comptroller c = bridge.createComptroller(address(this));
    assertEq(c.owner(), address(this));
  }

  function testMulticallable() public {
    bytes[] memory functions = new bytes[](4);
    functions[0] = abi.encodeWithSignature(
      "setRoleCapability(uint8,bytes4,bool)",
      0,
      omnitokenImplementation.mint.selector,
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
      omnitokenImplementation.mint.selector
    );
    bytes[] memory results = comptroller.multicall(functions);
    assertTrue(abi.decode(results[2], (bool)));
    assertTrue(abi.decode(results[3], (bool)));
  }

  function testOwner() public {
    assertEq(comptroller.owner(), address(this));
  }

  function testSetOwner() public {
    comptroller.setOwner(ownerAddress);
    assertEq(comptroller.owner(), ownerAddress);
  }

  function testAuthority() public {
    assertEq(address(comptroller.authority()), address(comptroller));
  }

  function comptrollerTransfer(uint256 amount) internal {
    hevm.assume(amount < address(this).balance);
    payable(address(comptroller)).transfer(amount);
  }

  function testWithdrawTo(address receiver, uint256 amount) public {
    hevm.assume(!BoringAddress.isContract(receiver));
    comptrollerTransfer(amount);
    comptroller.withdrawTo(receiver, amount);
    assertEq(receiver.balance, amount);
  }

  function testWithdrawToRequiresAuth(address caller, uint256 amount) public {
    comptrollerTransfer(amount);
    hevm.expectRevert("UNAUTHORIZED");
    hevm.prank(caller);
    comptroller.withdrawTo(caller, amount);
  }
}
