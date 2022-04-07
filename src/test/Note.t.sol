// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { TestBase } from "@protocol/test/TestBase.sol";

contract NoteTest is TestBase {
  function testOwnerCanMint(address to, uint256 amount) public {
    hevm.assume(to != address(0) && to != owner);

    hevm.startPrank(owner);
    edn.mintTo(to, amount);
    hevm.stopPrank();

    assertEq(edn.balanceOf(to), amount);
  }

  function testFailMintTo(address to, uint256 amount) public {
    edn.mintTo(to, amount);
  }
}