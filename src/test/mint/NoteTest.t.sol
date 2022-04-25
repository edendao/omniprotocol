// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {MockERC20} from "@rari-capital/solmate/test/utils/mocks/MockERC20.sol";

import {ChainEnvironmentTest, Note} from "@protocol/test/ChainEnvironmentTest.t.sol";

contract NoteTest is ChainEnvironmentTest {
  MockERC20 internal fwaum =
    new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
  Note internal fwaumNote =
    new Note(
      address(fwaum),
      address(comptroller),
      "Friends with Assets Under Management",
      "FWAUM",
      18
    );

  function testMintGas() public {
    note.mintTo(address(this), 10_000_000);
  }

  function testNoteWrapping(address caller, uint256 amount) public {
    hevm.assume(amount > 0 && caller != address(0));
    fwaum.mint(caller, amount);

    hevm.startPrank(caller);
    fwaum.approve(address(fwaumNote), amount);
    fwaumNote.wrap(amount);

    assertEq(fwaumNote.balanceOf(caller), amount);

    fwaumNote.unwrap(amount);
    hevm.stopPrank();

    uint256 fee = amount / 100;
    assertEq(fwaum.balanceOf(caller), amount - fee);
    assertEq(fwaumNote.balanceOf(caller), 0);
    assertEq(fwaumNote.balanceOf(address(fwaumNote)), fee);
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

  function testBurnRequiresAuth(address caller, uint256 amount) public {
    hevm.assume(caller != address(this));
    note.mintTo(caller, amount);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    note.burnFrom(caller, amount);
  }

  function testFailWrapNullToken() public {
    note.wrap(42);
  }
}
