// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { NiftyOmnifity } from "@protocol/spells/NiftyOmnifity.sol";
import { ManifestDestiny } from "@protocol/spells/ManifestDestiny.sol";

contract ManifestDestinyTest is TestBase {
  NiftyOmnifity internal nifty =
    new NiftyOmnifity(address(authority), address(passport));
  ManifestDestiny internal manifest =
    new ManifestDestiny(address(authority), address(edn), address(nifty));

  function setUp() public {
    hevm.startPrank(owner);

    uint8 manifestor = 0;
    authority.setRoleCapability(manifestor, edn.mintTo.selector, true);
    authority.setRoleCapability(manifestor, nifty.cast.selector, true);
    authority.setUserRole(address(manifest), manifestor, true);

    domain.transferFrom(
      address(this),
      address(nifty),
      passport.TOKEN_URI_DOMAIN()
    );

    hevm.stopPrank();
  }

  function testCast(uint256 value, bytes memory uri) public {
    hevm.assume(value < myAddress.balance);

    (uint256 passportId, uint256 balance) = manifest.cast{ value: value }(uri);

    assertEq(passport.tokenURI(passportId), string(uri));
    assertEq(passport.ownerOf(passportId), myAddress);
    assertEq(balance, manifest.preview(value));
  }

  function testCall(uint256 value) public {
    hevm.assume(value < myAddress.balance);

    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, bytes memory res) = address(manifest).call{ value: value }("");
    require(ok, string(res));

    assertEq(passport.ownerOf(passport.idOf(myAddress)), myAddress);
    assertEq(edn.balanceOf(myAddress), manifest.preview(value));
  }
}
