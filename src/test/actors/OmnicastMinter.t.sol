// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

import {OmnicastMinter} from "@protocol/actors/OmnicastMinter.sol";

contract OmnicastMinterTest is TestEnvironment {
  OmnicastMinter internal minter =
    new OmnicastMinter(address(comptroller), address(omnicast), address(note));

  function setUp() public {
    uint8 minterRole = 255;
    comptroller.setRoleCapability(minterRole, note.mintTo.selector, true);
    comptroller.setRoleCapability(minterRole, omnicast.mintTo.selector, true);
    comptroller.setUserRole(address(minter), minterRole, true);
  }

  function testClaim(address caller, uint256 value) public {
    hevm.deal(caller, value);
    hevm.startPrank(caller);

    hevm.assume(
      caller != address(this) &&
        caller != address(0) &&
        value > minter.claimRequirement()
    );

    (uint256 omnicastId, uint256 notesReceived) = minter.claim{value: value}();

    assertEq(omnicastId, omnicast.idOf(caller));
    assertEq(notesReceived, minter.optimismNotes(value));

    hevm.stopPrank();
  }

  function testReceive(address caller, uint256 value) public {
    hevm.deal(caller, value);
    hevm.startPrank(caller);
    hevm.assume(
      caller != address(this) &&
        caller != address(0) &&
        value > minter.claimRequirement()
    );
    (bool ok, ) = address(minter).call{value: value}("");
    assertTrue(ok);
    assertEq(1, omnicast.balanceOf(caller));
    assertEq(caller, omnicast.ownerOf(omnicast.idOf(caller)));
    hevm.stopPrank();
  }
}
