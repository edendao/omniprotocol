// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Note} from "@test/ChainEnvironmentTest.t.sol";

contract NoteTest is ChainEnvironmentTest {
  function testCloneGas() public {
    Note n = bridge.createNote(
      address(comptroller),
      "Frontier Carbon 2",
      "TIME2",
      3
    );
    assertEq(n.symbol(), "TIME2");
  }

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
