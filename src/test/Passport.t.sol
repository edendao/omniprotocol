// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { PassportMinter } from "@protocol/actors/PassportMinter.sol";
import { TestBase } from "@protocol/test/TestBase.sol";

contract PassportTest is TestBase {
  function testOwnerCanMint(address _to) public {
    if (_to == address(0)) return;

    hevm.startPrank(owner);
    passport.mintTo(_to);
    hevm.stopPrank();
    assertEq(passport.ownerOf(passport.totalSupply() - 1), _to);
  }

  function testReputation() public {
    hevm.startPrank(owner);
    passport.mintTo(address(this));
    hevm.stopPrank();
  }

  function testFailMintTo(address _to) public {
    passport.mintTo(_to);
  }
}
