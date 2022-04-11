// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestBase} from "@protocol/test/TestBase.sol";

contract OmnicastTest is TestBase {
  function testFindOrMintTo(address to) public {
    hevm.assume(to != address(0));
    omnicast.mintTo(to);
    assertEq(omnicast.balanceOf(to), 1);
    assertEq(omnicast.ownerOf(omnicast.idOf(to)), to);

    hevm.expectRevert("Omnicast: NOT_AVAILABLE");
    omnicast.mintTo(to);
  }
}
