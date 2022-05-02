// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, console} from "@test/ChainEnvironmentTest.t.sol";

contract PassportTest is ChainEnvironmentTest {
  function testMintGas() public {
    passport.mintTo(address(this), omnicast.idOf(address(this)));
  }

  function testMint(address caller, uint256 value) public {
    hevm.assume(
      caller != address(0) && caller != myAddress && value >= 0.01 ether
    );
    hevm.deal(caller, value);

    hevm.prank(caller);
    uint256 id = passport.mint{value: value}();

    assertEq(passport.balanceOf(caller), 1);
    assertEq(omnicast.idOf(caller), id);
    assertEq(passport.ownerOf(id), caller);
  }

  function testReceiveMint(address caller, uint256 value) public {
    hevm.assume(
      caller != address(this) && caller != address(0) && value >= 0.01 ether
    );
    hevm.deal(caller, value);

    hevm.prank(caller);
    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, ) = address(passport).call{value: value}("");

    assertTrue(ok);
    assertEq(1, passport.balanceOf(caller));
    assertEq(caller, passport.ownerOf(omnicast.idOf(caller)));
  }

  function testNoteMintRequiresAuth(address caller) public {
    hevm.assume(caller != address(0) && caller != address(this));

    uint256 id = omnicast.idOf(caller);
    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    passport.mintTo(caller, id);
  }
}
