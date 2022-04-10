// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestBase} from "@protocol/test/TestBase.sol";

contract PassportTest is TestBase {
  function testFindOrMintFor(address to) public {
    hevm.assume(to != address(0));
    // Referential Transparency
    assertEq(pass.findOrMintFor(to), pass.findOrMintFor(to));
    // Idempotency
    assertEq(pass.balanceOf(to), 1);
    // Ownership
    assertEq(pass.ownerOf(pass.idOf(to)), to);
  }
}
