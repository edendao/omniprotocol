// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import {ChainEnvironmentTest, Note} from "@test/ChainEnvironmentTest.t.sol";

contract NoteTest is ChainEnvironmentTest {
  function testMintGas() public {
    note.mintTo(address(this), 10_000_000);
  }

  function testMint(address to, uint128 amount) public {
    hevm.assume(to != address(0) && note.balanceOf(to) == 0);
    note.mintTo(to, amount);

    assertEq(note.balanceOf(to), amount);
  }

  function testMintRequiresAuth(address caller, uint128 amount) public {
    hevm.assume(caller != address(this));
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    note.mintTo(caller, amount);
  }

  function testBurnRequiresAuth(address caller, uint128 amount) public {
    hevm.assume(caller != address(this));
    note.mintTo(caller, amount);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    note.burnFrom(caller, amount);
  }
}
