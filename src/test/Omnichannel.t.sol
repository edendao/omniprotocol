// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

contract OmnichannelTest is TestEnvironment {
  uint256 internal immutable omnichannelId = omnichannel.idOf("prosperity");

  function testMintGas() public {
    omnichannel.mintTo(address(this), omnichannelId);
  }

  function testMintTo(address to) public {
    hevm.assume(to != address(0));

    omnichannel.mintTo(to, omnichannelId);

    assertEq(omnichannel.ownerOf(omnichannelId), to);
  }

  function testMintToRequiresAuth(address caller) public {
    hevm.assume(caller != address(0) && caller != myAddress);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    omnichannel.mintTo(caller, omnichannelId);
  }
}
