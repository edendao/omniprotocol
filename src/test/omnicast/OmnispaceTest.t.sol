// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest} from "@protocol/test/ChainEnvironmentTest.t.sol";

import {Omnispace} from "@protocol/omnicast/Omnispace.sol";

contract OmnispaceTest is ChainEnvironmentTest {
  Omnispace internal minter =
    new Omnispace(
      address(comptroller),
      address(omnichannel),
      address(omnicast)
    );

  function setUp() public {
    uint8 omnispaceRole = 255;
    comptroller.setRoleCapability(
      omnispaceRole,
      omnichannel.mintTo.selector,
      true
    );
    comptroller.setRoleCapability(
      omnispaceRole,
      omnicast.mintTo.selector,
      true
    );
    comptroller.setUserRole(address(minter), omnispaceRole, true);
  }

  function testClaimGas() public {
    minter.claim{value: 0.25 ether}();
  }

  function testClaim(address caller, uint256 value) public {
    hevm.assume(
      caller != address(this) && caller != address(0) && value >= 0.01 ether
    );
    hevm.deal(caller, value);

    hevm.prank(caller);
    uint256 omnicastId = minter.claim{value: value}();

    assertEq(omnicastId, omnicast.idOf(caller));
  }

  function testReceive(address caller, uint256 value) public {
    hevm.assume(
      caller != address(this) && caller != address(0) && value >= 0.01 ether
    );
    hevm.deal(caller, value);

    hevm.prank(caller);
    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, ) = address(minter).call{value: value}("");

    assertTrue(ok);
    assertEq(1, omnicast.balanceOf(caller));
    assertEq(caller, omnicast.ownerOf(omnicast.idOf(caller)));
  }

  function testRegisterGas() public {
    minter.register{value: 1 ether}("prosperity");
  }

  function testRegister(address caller, uint256 value) public {
    hevm.deal(caller, value);

    hevm.assume(
      caller != address(this) &&
        caller != address(0) &&
        value >= (minter.channelsRegisteredBy(caller) + 1) * 0.05 ether
    );

    hevm.prank(caller);
    uint256 omnichannelId = minter.register{value: value}("prosperity");

    assertEq(omnichannelId, omnichannel.idOf("prosperity"));
  }
}
