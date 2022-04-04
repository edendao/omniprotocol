// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { PassportMinter } from "@protocol/actors/PassportMinter.sol";

contract PassportMinterTest is TestBase {
  PassportMinter internal minter =
    new PassportMinter(address(authority), address(edn), address(passport));

  address internal myAddress = address(this);

  function setUp() public {
    hevm.startPrank(owner);

    uint8 actor = 0;
    authority.setRoleCapability(actor, edn.mintTo.selector, true);
    authority.setRoleCapability(actor, passport.ensureMintedTo.selector, true);
    authority.setRoleCapability(actor, passport.setTokenURI.selector, true);
    authority.setUserRole(address(minter), actor, true);

    hevm.stopPrank();
  }

  function testPassportMinterPerform(uint256 value) public {
    hevm.assume(myAddress.balance > value);

    minter.perform{ value: value }("");
    assertEq(passport.ownerOf(passport.idOf(myAddress)), myAddress);
    assertEq(edn.balanceOf(myAddress), minter.preview(value));
  }

  function testPassportMinterCall(uint256 value) public {
    hevm.assume(myAddress.balance > value);

    (bool ok, bytes memory res) = address(minter).call{ value: value }("");
    require(ok, string(res));

    assertEq(passport.ownerOf(passport.idOf(myAddress)), myAddress);
    assertEq(edn.balanceOf(myAddress), minter.preview(value));
  }
}
