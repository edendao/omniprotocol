// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Omnitoken} from "./ChainEnvironmentTest.t.sol";

contract OmnitokenTest is ChainEnvironmentTest {
  Omnitoken public omnitoken;

  function setUp() public override {
    super.setUp();

    omnitoken = Omnitoken(
      factory.createToken(address(steward), "Frontier Carbon", "TIME", 3)
    );
  }

  function testCloneGas() public returns (Omnitoken n) {
    n = Omnitoken(
      factory.createToken(address(steward), "Frontier Carbon 2", "TIME2", 3)
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

  function testSenderSanctions(address sender, uint128 amount) public {
    hevm.assume(sender != address(0) && sender != address(this));
    omnitoken.mint(sender, amount);
    steward.setUserSanction(sender, true);

    hevm.expectRevert("UNAUTHORIZED");
    hevm.prank(sender);
    omnitoken.transfer(beneficiary, amount);
  }

  function testRecipientSanctions(address recipient, uint128 amount) public {
    hevm.assume(recipient != address(0) && recipient != address(this));
    omnitoken.mint(address(this), amount);
    steward.setUserSanction(recipient, true);

    hevm.expectRevert("UNAUTHORIZED");
    omnitoken.transfer(recipient, amount);
  }
}
