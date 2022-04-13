// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

contract OmnichannelTest is TestEnvironment {
  function testMintTo(address to) public {
    hevm.assume(to != address(0));

    uint256 omnichannelId = omnichannel.mintTo(to, "prosperity");

    assertEq(omnichannel.ownerOf(omnichannelId), to);
    assertEq(omnichannelId, omnichannel.idOf("prosperity"));
  }

  function testMintToRequiresAuth(address caller) public {
    hevm.assume(caller != address(0) && caller != myAddress);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    omnichannel.mintTo(caller, "prosperity");
  }
}
