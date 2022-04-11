// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestBase} from "@protocol/test/TestBase.sol";

contract OmnicastTest is TestBase {
  function setUp() public {
    hevm.startPrank(owner);

    uint8 noteMinter = 0;
    authority.setRoleCapability(noteMinter, edn.mintTo.selector, true);
    authority.setUserRole(address(omnicast), noteMinter, true);

    hevm.stopPrank();
  }

  function testMint(address to) public {
    hevm.assume(to != address(0));

    omnicast.mintTo{value: 0.5 ether}(to);

    assertEq(omnicast.balanceOf(to), 1);
    assertEq(omnicast.ownerOf(omnicast.idOf(to)), to);
  }

  function testInsufficientValue(address to) public {
    hevm.expectRevert("Omnicast: INSUFFICIENT_VALUE");
    omnicast.mintTo(to);
  }

  function testNotAvailable(address to) public {
    testMint(to);
    hevm.expectRevert("Omnicast: NOT_AVAILABLE");
    testMint(to);
  }
}
