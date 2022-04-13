// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

contract NoteTest is TestEnvironment {
  function testMintGas() public {
    note.mintTo(address(this), 10_000_000);
  }

  function testMintTo(address to, uint256 amount) public {
    hevm.assume(to != address(0));
    note.mintTo(to, amount);

    assertEq(note.balanceOf(to), amount);
  }

  function testMintRequiresAuth(address caller, uint256 amount) public {
    hevm.assume(caller != address(this));
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    note.mintTo(caller, amount);
  }

  function testBurnRequiresAuth(address from, uint256 amount) public {
    note.mintTo(from, amount);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(from);
    note.burnFrom(from, amount);
  }
}
