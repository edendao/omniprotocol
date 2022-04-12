// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

contract ComptrollerTest is TestEnvironment {
  function testOwner() public {
    assertEq(comptroller.owner(), ownerAddress);
  }

  function testAuthority() public {
    assertEq(address(comptroller.authority()), address(comptroller));
  }

  function comptrollerTransfer(uint256 amount) internal {
    hevm.assume(amount < myAddress.balance);
    payable(address(comptroller)).transfer(amount);
  }

  function testWithdrawTo(address receiver, uint256 amount) public {
    comptrollerTransfer(amount);

    hevm.prank(ownerAddress);
    comptroller.withdrawTo(receiver, amount);

    assertEq(receiver.balance, amount);
  }

  function testUnauthorizedWithdrawTo(address receiver, uint256 amount) public {
    comptrollerTransfer(amount);

    hevm.expectRevert("UNAUTHORIZED");
    comptroller.withdrawTo(receiver, amount);
  }
}
