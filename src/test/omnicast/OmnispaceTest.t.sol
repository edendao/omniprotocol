// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, console} from "@protocol/test/ChainEnvironmentTest.t.sol";

import {Omnispace} from "@protocol/omnicast/Omnispace.sol";

contract OmnispaceTest is ChainEnvironmentTest {
  Omnispace internal minter =
    new Omnispace(
      address(comptroller),
      address(omnichannel),
      address(omnicast)
    );

  function setUp() public {
    bytes memory command = minter.capabilities(1);

    // emit log_named_bytes("[OMNISPACE CAPABILITIES]", command);
    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, ) = address(comptroller).call(command);
    require(ok, "Failed to permission Omnispace");
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
