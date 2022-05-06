// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Note} from "@test/ChainEnvironmentTest.t.sol";

contract NoteTest is ChainEnvironmentTest {
  Note public note;

  function setUp() public override {
    super.setUp();
    note = testCloneGas();
  }

  function testCloneGas() public returns (Note n) {
    n = bridge.createNote(address(comptroller), "Frontier Carbon", "TIME", 3);
  }

  function testMintGas() public {
    note.mintTo(address(this), 10_000_000);
  }

  function testMint(address to, uint128 amount) public {
    hevm.assume(to != address(0) && note.balanceOf(to) == 0);
    note.mintTo(to, amount);

    assertEq(note.balanceOf(to), amount);
  }

  function testMintRequiresAuth(address to, uint128 amount) public {
    hevm.assume(to != address(0) && note.balanceOf(to) == 0);
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(to);
    note.mintTo(to, amount);
  }

  function testBurnRequiresAuth(address from, uint128 amount) public {
    hevm.assume(!comptroller.isAuthorized(from, note.burnFrom.selector));
    note.mintTo(from, amount);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(from);
    note.burnFrom(from, amount);
  }
}
