// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {BaseProtocolDeployerTest} from "@protocol/test/chainops/0_BaseProtocolDeployer.t.sol";

contract OmnichannelTest is BaseProtocolDeployerTest {
  function testMintGas() public {
    omnichannel.mint{value: 0.05 ether}("prosperity");
  }

  function testMintToGas() public {
    hevm.startPrank(owner);
    omnichannel.mintTo(myAddress, "prosperity");
    hevm.stopPrank();
  }

  function testMint(address to) public {
    hevm.assume(to != address(0) && to != owner);
    hevm.deal(to, 0.05 ether);
    hevm.startPrank(to);

    (uint256 channelId, uint256 noteReceived) = omnichannel.mint{
      value: 0.05 ether
    }("prosperity");

    hevm.stopPrank();

    assertEq(omnichannel.balanceOf(to), 1);
    assertEq(omnichannel.ownerOf(channelId), to);
    assertEq(channelId, omnichannel.idOf("prosperity"));
    assertEq(note.balanceOf(to), noteReceived);
  }

  function testInsufficientValue(address to) public {
    hevm.assume(to != address(0) && to != owner);

    hevm.expectRevert("Omnichannel: INSUFFICIENT_VALUE");
    omnichannel.mint{value: 0.025 ether}("prosperity");
  }
}
