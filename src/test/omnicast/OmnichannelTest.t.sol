// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest} from "@protocol/test/ChainEnvironmentTest.t.sol";

contract OmnichannelTest is ChainEnvironmentTest {
  string public constant label = "prosperity";

  function testMintGas() public {
    omnichannel.mint(address(this), label);
  }

  function testMintTo(address to) public {
    hevm.assume(to != address(0));

    omnichannel.mint(to, label);

    assertEq(omnichannel.ownerOf(omnichannel.idOf(label)), to);
  }

  function testMintToRequiresAuth(address caller) public {
    hevm.assume(caller != address(0) && caller != myAddress);

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    omnichannel.mint(caller, label);
  }
}
