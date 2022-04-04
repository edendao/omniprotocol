// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { PassportMinter } from "@protocol/actors/PassportMinter.sol";
import { TestBase } from "@protocol/test/TestBase.sol";

contract PassportTest is TestBase {
  function testOwnerCanMint(address to) public {
    hevm.assume(to != address(0) && to != owner);

    hevm.startPrank(owner);
    passport.mintTo(to);
    hevm.stopPrank();

    assertEq(passport.balanceOf(to), 1);
    assertEq(passport.ownerOf(passport.idOf(to)), to);
  }

  function testFailMintTo(address to) public {
    passport.mintTo(to);
  }
}
