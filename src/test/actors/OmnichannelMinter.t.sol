// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest} from "@protocol/test/ChainEnvironment.t.sol";

import {OmnichannelMinter} from "@protocol/actors/OmnichannelMinter.sol";

contract OmnichannelMinterTest is ChainEnvironmentTest {
  OmnichannelMinter internal minter =
    new OmnichannelMinter(
      address(comptroller),
      address(note),
      address(omnichannel)
    );

  function setUp() public {
    uint8 noteMinterRole = 0;
    comptroller.setRoleCapability(noteMinterRole, note.mintTo.selector, true);
    comptroller.setUserRole(address(minter), noteMinterRole, true);

    uint8 omnicastMinterRole = 255;
    comptroller.setRoleCapability(
      omnicastMinterRole,
      omnicast.mintTo.selector,
      true
    );
    comptroller.setUserRole(address(minter), omnicastMinterRole, true);
  }

  function testClaimGas() public {
    minter.claim{value: minter.claimRequirement()}("prosperity");
  }

  function testClaim(address caller, uint256 value) public {
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
