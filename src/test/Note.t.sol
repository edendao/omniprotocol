// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

contract NoteTest is TestEnvironment {
  function testMintRequiresAuth(address to, uint256 amount) public {
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    note.mintTo(to, amount);
  }

  function testBurnRequiresAuth(address from, uint256 amount) public {
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    note.burnFrom(from, amount);
  }
}
