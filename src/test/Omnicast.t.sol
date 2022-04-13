// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment, console} from "@protocol/test/TestEnvironment.t.sol";

contract OmnicastTest is TestEnvironment {
  function testMintTo(address to) public {
    hevm.assume(to != address(0));

    uint256 omnicastId = omnicast.mintTo(to);

    assertEq(omnicast.balanceOf(to), 1);
    assertEq(omnicast.ownerOf(omnicastId), to);
  }

  function testMintNotAvailable(address to) public {
    hevm.assume(to != address(0));

    omnicast.mintTo(to);
    hevm.expectRevert("Omnicast: NOT_AVAILABLE");
    omnicast.mintTo(to);
  }

  function testMintRequiresAuth(address caller) public {
    hevm.assume(caller != address(0) && caller != myAddress);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    omnicast.mintTo(caller);
  }
}
