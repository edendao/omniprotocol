// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { NiftyOmnifity } from "@protocol/spells/NiftyOmnifity.sol";

contract NiftyOmnifityTest is TestBase {
  NiftyOmnifity internal spell =
    new NiftyOmnifity(address(authority), address(edn), address(pass));

  function setUp() public {
    hevm.startPrank(owner);

    uint8 mintXP = 0;
    authority.setRoleCapability(mintXP, edn.mintTo.selector, true);
    authority.setUserRole(address(spell), mintXP, true);

    dns.transferFrom(address(this), address(spell), dns.TOKEN_URI_DOMAIN());

    hevm.stopPrank();
  }

  function testCast(
    address from,
    uint256 concentration,
    bytes memory uri
  ) public {
    hevm.assume(from != address(0));
    hevm.deal(from, concentration);
    hevm.startPrank(from);

    (uint256 passId, uint256 xp) = spell.cast{ value: concentration }(
      from,
      uri
    );

    assertEq(pass.tokenURI(passId), string(uri));
    assertEq(pass.ownerOf(passId), from);
    assertEq(xp, spell.previewXP(concentration));

    hevm.stopPrank();
  }

  function testCall(address from, uint256 concentration) public {
    hevm.assume(from != address(0));
    hevm.deal(from, concentration);
    hevm.startPrank(from);

    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, bytes memory res) = address(spell).call{ value: concentration }(
      ""
    );
    require(ok, string(res));

    assertEq(pass.ownerOf(pass.idOf(from)), from);
    assertEq(edn.balanceOf(from), spell.previewXP(concentration));

    hevm.stopPrank();
  }
}
