// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { PassportMinter } from "@protocol/actors/PassportMinter.sol";

contract PassportMinterTest is TestBase {
  PassportMinter internal minter =
    new PassportMinter(address(authority), address(edn), address(passport));

  function setUp() public {
    uint8 minterRole = 0;
    hevm.startPrank(owner);
    authority.setRoleCapability(minterRole, edn.mintTo.selector, true);
    authority.setRoleCapability(minterRole, passport.mintTo.selector, true);
    authority.setUserRole(address(minter), minterRole, true);
    hevm.stopPrank();
  }

  function testPassportMinterPerform(uint256 value, bytes memory uri) public {
    if (address(this).balance < value) return;

    minter.perform{ value: value }(uri);
    assertEq(passport.ownerOf(passport.totalSupply()), address(this));
    assertEq(edn.balanceOf(address(this)), minter.previewMint(value));
  }

  function testPassportMinterCall(uint256 value) public {
    if (address(this).balance < value) return;

    (bool success, bytes memory returndata) = address(minter).call{
      value: value
    }("");
    require(success, string(returndata));
    assertEq(passport.ownerOf(passport.totalSupply()), address(this));
    assertEq(edn.balanceOf(address(this)), minter.previewMint(value));
  }
}
