// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

contract OmnichannelTest is TestEnvironment {
  function testMintGas() public {
    omnichannel.mint{value: 0.05 ether}("prosperity");
  }

  function testMintToGas() public {
    hevm.prank(ownerAddress);
    omnichannel.mintTo(myAddress, "prosperity");
  }

  function testMint(address to) public {
    hevm.assume(to != address(0) && to != ownerAddress);
    hevm.deal(to, 0.05 ether);

    hevm.prank(to);
    (uint256 channelId, uint256 noteReceived) = omnichannel.mint{
      value: 0.05 ether
    }("prosperity");

    assertEq(omnichannel.balanceOf(to), 1);
    assertEq(omnichannel.ownerOf(channelId), to);
    assertEq(channelId, omnichannel.idOf("prosperity"));
    assertEq(note.balanceOf(to), noteReceived);
  }

  function testInsufficientValue() public {
    hevm.assume(myAddress.balance >= 0.025 ether);
    hevm.expectRevert("Omnichannel: INSUFFICIENT_VALUE");
    omnichannel.mint{value: 0.025 ether}("prosperity");
  }
}
