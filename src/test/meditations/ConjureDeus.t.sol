// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

import {TestBase} from "@protocol/test/TestBase.sol";

import {NiftyOmnifity} from "@protocol/meditations/NiftyOmnifity.sol";
import {ConjureDeus} from "@protocol/meditations/ConjureDeus.sol";

contract ConjureDeusTest is TestBase {
  ConjureDeus internal meditation =
    new ConjureDeus(address(authority), address(edn), address(dns));

  function setUp() public {
    hevm.startPrank(owner);

    uint8 mintXP = 0;
    authority.setRoleCapability(mintXP, edn.mintTo.selector, true);
    authority.setUserRole(address(meditation), mintXP, true);

    hevm.stopPrank();
  }

  function testCast(
    address from,
    uint256 id,
    uint256 value
  ) public {
    hevm.assume(
      meditation.minimumResonance() <= value &&
        from != address(0) &&
        dns.ownerOf(id) == address(0)
    );
    hevm.deal(from, value);
    hevm.startPrank(from);

    uint256 xp = meditation.perform{value: value}(id);

    assertEq(dns.ownerOf(id), from);
    assertEq(xp, meditation.previewXP(value));

    hevm.stopPrank();
  }

  function testCall(address from, uint256 value) public {
    uint256 id = uint256(uint160(from));
    hevm.assume(
      meditation.minimumResonance() <= value &&
        from != address(0) &&
        dns.ownerOf(id) == address(0)
    );
    hevm.deal(from, value);
    hevm.startPrank(from);

    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, bytes memory res) = address(meditation).call{value: value}("");
    require(ok, string(res));

    assertEq(dns.ownerOf(id), from);
    assertEq(edn.balanceOf(from), meditation.previewXP(value));

    hevm.stopPrank();
  }
}
