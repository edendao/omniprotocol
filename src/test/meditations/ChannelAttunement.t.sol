// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

import {TestBase} from "@protocol/test/TestBase.sol";

import {ChannelAttunement} from "@protocol/meditations/ChannelAttunement.sol";

contract ChannelAttunementTest is TestBase {
  ChannelAttunement internal meditation =
    new ChannelAttunement(address(authority), address(edn), address(dns));

  function setUp() public {
    hevm.startPrank(owner);

    uint8 noteMinter = 0;
    authority.setRoleCapability(noteMinter, edn.mintTo.selector, true);
    authority.setUserRole(address(meditation), noteMinter, true);

    uint8 channelMinter = 1;
    authority.setRoleCapability(channelMinter, dns.mintTo.selector, true);
    authority.setUserRole(address(meditation), channelMinter, true);

    hevm.stopPrank();
  }

  function testPerformWithNamehash(address from, uint256 value) public {
    hevm.assume(
      from != address(0) &&
        value > meditation.giftRequired(from) &&
        meditation.canPerform(from) &&
        meditation.canPerform("prosperity")
    );
    hevm.deal(from, value);
    hevm.startPrank(from);

    uint256 xp = meditation.perform{value: value}("prosperity");

    assertEq(dns.ownerOf(dns.idOf("prosperity")), from);
    assertEq(xp, meditation.previewEDN(value));
    hevm.stopPrank();
  }

  function testCall(address from, uint256 value) public {
    uint256 channelId = uint256(uint160(from));
    hevm.assume(
      from != address(0) &&
        value > meditation.giftRequired(from) &&
        meditation.canPerform(from) &&
        meditation.canPerform(channelId)
    );
    hevm.deal(from, value);
    hevm.startPrank(from);

    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, bytes memory res) = address(meditation).call{value: value}("");
    require(ok, string(res));

    assertEq(dns.ownerOf(channelId), from);
    assertEq(edn.balanceOf(from), meditation.previewEDN(value));
    hevm.stopPrank();
  }
}
