// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Omnitoken} from "@test/ChainEnvironmentTest.t.sol";

contract OmnitokenTest is ChainEnvironmentTest {
  Omnitoken public omnitoken;

  function setUp() public override {
    super.setUp();
    omnitoken = testCloneGas();
  }

  function testCloneGas() public returns (Omnitoken n) {
    n = Omnitoken(
      token.clone(
        abi.encode(
          address(comptroller),
          address(layerZeroEndpoint),
          "Frontier Carbon",
          "TIME",
          3
        )
      )
    );
  }

  function testMintGas() public {
    omnitoken.mint(address(this), 10_000_000);
  }

  function testMint(address to, uint128 amount) public {
    hevm.assume(to != address(0) && omnitoken.balanceOf(to) == 0);
    omnitoken.mint(to, amount);

    assertEq(omnitoken.balanceOf(to), amount);
  }

  function testMintRequiresAuth(address to, uint128 amount) public {
    hevm.assume(
      to != address(0) && to != address(this) && omnitoken.balanceOf(to) == 0
    );
    hevm.expectRevert("UNAUTHORIZED");
    hevm.prank(to);
    omnitoken.mint(to, amount);
  }
}
