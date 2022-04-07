// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { NiftyOmnifity } from "@protocol/spells/NiftyOmnifity.sol";
import { ConjureDeus } from "@protocol/spells/ConjureDeus.sol";

contract ConjureDeusTest is TestBase {
  ConjureDeus internal spell =
    new ConjureDeus(address(authority), address(edn), address(dns));

  function setUp() public {
    hevm.startPrank(owner);

    uint8 mintXP = 0;
    authority.setRoleCapability(mintXP, edn.mintTo.selector, true);
    authority.setUserRole(address(spell), mintXP, true);

    hevm.stopPrank();
  }

  function testCast(
    address from,
    uint256 id,
    uint256 value
  ) public {
    hevm.assume(
      0.01 ether <= value && from != address(0) && dns.ownerOf(id) == address(0)
    );
    hevm.deal(from, value);
    hevm.startPrank(from);

    uint256 xp = spell.cast{ value: value }(id);

    assertEq(dns.ownerOf(id), from);
    assertEq(xp, spell.previewXP(value));

    hevm.stopPrank();
  }

  function testCall(address from, uint256 value) public {
    uint256 id = uint256(uint160(from));
    hevm.assume(
      0.01 ether <= value && from != address(0) && dns.ownerOf(id) == address(0)
    );
    hevm.deal(from, value);
    hevm.startPrank(from);

    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, bytes memory res) = address(spell).call{ value: value }("");
    require(ok, string(res));

    assertEq(dns.ownerOf(id), from);
    assertEq(edn.balanceOf(from), spell.previewXP(value));

    hevm.stopPrank();
  }
}
