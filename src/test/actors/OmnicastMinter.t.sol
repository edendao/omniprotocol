// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest} from "@protocol/test/ChainEnvironment.t.sol";

import {OmnicastMinter} from "@protocol/actors/OmnicastMinter.sol";

contract OmnicastMinterTest is ChainEnvironmentTest {
  OmnicastMinter internal minter =
    new OmnicastMinter(address(comptroller), address(note), address(omnicast));

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
    minter.claim{value: minter.claimRequirement()}();
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
    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, ) = address(minter).call{value: value}("");
    assertTrue(ok);
    assertEq(1, omnicast.balanceOf(caller));
    assertEq(caller, omnicast.ownerOf(omnicast.idOf(caller)));
    hevm.stopPrank();
  }
}
