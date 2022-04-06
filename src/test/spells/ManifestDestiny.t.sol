// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { ManifestDestiny } from "@protocol/spells/ManifestDestiny.sol";

contract ManifestDestinyTest is TestBase {
  ManifestDestiny internal manifest =
    new ManifestDestiny(address(authority), address(edn), address(passport));

  function setUp() public {
    hevm.startPrank(owner);

    uint8 actor = 0;
    authority.setRoleCapability(actor, edn.mintTo.selector, true);
    authority.setRoleCapability(actor, passport.findOrMintFor.selector, true);
    authority.setRoleCapability(actor, passport.setToken.selector, true);
    authority.setUserRole(address(manifest), actor, true);

    hevm.stopPrank();
  }

  function testCast(uint256 value, string memory uri) public {
    hevm.assume(myAddress.balance > value);

    manifest.cast{ value: value }(uri);

    assertEq(passport.tokenURI(passport.idOf(myAddress)), uri);
    assertEq(passport.ownerOf(passport.idOf(myAddress)), myAddress);
    assertEq(edn.balanceOf(myAddress), manifest.preview(value));
  }

  function testCall(uint256 value) public {
    hevm.assume(myAddress.balance > value);

    (bool ok, bytes memory res) = address(manifest).call{ value: value }("");
    require(ok, string(res));

    assertEq(passport.ownerOf(passport.idOf(myAddress)), myAddress);
    assertEq(edn.balanceOf(myAddress), manifest.preview(value));
  }
}
