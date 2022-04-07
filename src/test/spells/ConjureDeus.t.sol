// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { NiftyOmnifity } from "@protocol/spells/NiftyOmnifity.sol";
import { ConjureDeus } from "@protocol/spells/ConjureDeus.sol";

contract ConjureDeusTest is TestBase {
  NiftyOmnifity internal nifty =
    new NiftyOmnifity(address(authority), address(passport));
  ConjureDeus internal conjure =
    new ConjureDeus(
      address(authority),
      address(edn),
      address(nifty),
      address(domain)
    );

  function setUp() public {
    hevm.startPrank(owner);

    uint8 conjurer = 0;
    authority.setRoleCapability(conjurer, edn.mintTo.selector, true);
    authority.setRoleCapability(conjurer, nifty.cast.selector, true);
    authority.setUserRole(address(conjure), conjurer, true);

    domain.transferFrom(
      address(this),
      address(nifty),
      passport.TOKEN_URI_DOMAIN()
    );

    hevm.stopPrank();
  }

  function testCast(uint256 value, bytes memory uri) public {
    hevm.assume(0.01 ether <= value && value < myAddress.balance);

    uint256 domainId = 123456678909876543212;

    (uint256 passportId, uint256 balance) = conjure.cast{ value: value }(
      domainId,
      uri
    );

    assertEq(domain.ownerOf(domainId), myAddress);
    assertEq(passport.ownerOf(passportId), myAddress);
    assertEq(passport.tokenURI(passportId), string(uri));
    assertEq(balance, conjure.preview(value));
  }

  function testCall(uint256 value) public {
    hevm.assume(0.01 ether <= value && value < myAddress.balance);

    // solhint-disable-next-line avoid-low-level-calls
    (bool ok, bytes memory res) = address(conjure).call{ value: value }("");
    require(ok, string(res));

    uint256 id = passport.idOf(myAddress);
    assertEq(domain.ownerOf(id), myAddress);
    assertEq(passport.ownerOf(id), myAddress);
    assertEq(edn.balanceOf(myAddress), conjure.preview(value));
  }
}
