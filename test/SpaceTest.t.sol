// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest} from "@test/ChainEnvironmentTest.t.sol";

contract SpaceTest is ChainEnvironmentTest {
  uint256 internal immutable spaceId = omnicast.idOf("prosperity");

  function testMintNameGas() public {
    hevm.prank(address(this), address(this));
    space.mint{value: 1 ether}("prosperity");
  }

  function testMintName(address caller, uint256 value) public {
    hevm.assume(
      caller != address(this) &&
        caller != address(0) &&
        value >= (space.countRegisteredBy(caller) + 1) * 0.05 ether
    );
    hevm.deal(caller, value);

    hevm.prank(caller, caller);
    uint256 omnicastId = space.mint{value: value}("prosperity");

    assertEq(omnicastId, spaceId);
  }
}
