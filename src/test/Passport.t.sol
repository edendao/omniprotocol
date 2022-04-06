// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { TestBase } from "@protocol/test/TestBase.sol";

contract PassportTest is TestBase {
  function testOwnerCanMint(address to) public {
    hevm.assume(to != address(0));

    passport.findOrMintFor(to);

    assertEq(passport.balanceOf(to), 1);
    assertEq(passport.ownerOf(passport.idOf(to)), to);
  }
}
