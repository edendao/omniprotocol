// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TestEnvironment} from "@protocol/test/TestEnvironment.t.sol";

import {OmnichannelMinter} from "@protocol/actors/OmnichannelMinter.sol";

contract OmnichannelMinterTest is TestEnvironment {
  OmnichannelMinter internal minter =
    new OmnichannelMinter(
      address(comptroller),
      address(omnichannel),
      address(note)
    );

  function setUp() public {
    uint8 minterRole = 255;
    comptroller.setRoleCapability(minterRole, note.mintTo.selector, true);
    comptroller.setRoleCapability(
      minterRole,
      omnichannel.mintTo.selector,
      true
    );
    comptroller.setUserRole(address(minter), minterRole, true);
  }

  function testReserve(address caller, uint256 value) public {
    hevm.deal(caller, value);
    hevm.startPrank(caller);

    hevm.assume(
      caller != address(this) &&
        caller != address(0) &&
        value > minter.claimRequirement()
    );

    (uint256 omnichannelId, uint256 notesReceived) = minter.claim{value: value}(
      "prosperity"
    );

    assertEq(omnichannelId, omnichannel.idOf("prosperity"));
    assertEq(notesReceived, minter.optimismNotes(value));

    hevm.stopPrank();
  }
}
