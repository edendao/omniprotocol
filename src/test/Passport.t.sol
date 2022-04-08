// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestBase} from "@protocol/test/TestBase.sol";

contract PassportTest is TestBase {
  function testFindOrMintFor(address to) public {
    hevm.assume(to != address(0));

    pass.findOrMintFor(to);
    pass.findOrMintFor(to); // tests idempotency

    assertEq(pass.balanceOf(to), 1);
    assertEq(pass.ownerOf(pass.idOf(to)), to);
  }
}
