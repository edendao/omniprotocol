// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

import {MockBoringMultipleNFT} from "@boring/mocks/MockBoringMultipleNFT.sol";

import {TestBase} from "@protocol/test/TestBase.sol";

import {NiftyOmnifity} from "@protocol/meditations/NiftyOmnifity.sol";

contract NiftyOmnifityTest is TestBase {
  NiftyOmnifity internal meditation =
    new NiftyOmnifity(address(authority), address(edn), address(omnicast));

  MockBoringMultipleNFT internal bayc = new MockBoringMultipleNFT();

  function setUp() public {
    hevm.startPrank(owner);

    channel.transferFrom(
      address(this),
      address(meditation),
      omnicast.TOKENURI_CHANNEL()
    );

    uint8 noteMinter = 0;
    authority.setRoleCapability(noteMinter, edn.mintTo.selector, true);
    authority.setUserRole(address(meditation), noteMinter, true);

    uint8 omnicastWriter = 2;
    authority.setRoleCapability(
      omnicastWriter,
      omnicast.sendMessage.selector,
      true
    );
    authority.setUserRole(address(meditation), omnicastWriter, true);

    hevm.stopPrank();
  }

  function testPerformWithNifty(address from, uint256 value) public {
    hevm.assume(from != address(0));
    hevm.deal(from, value);
    hevm.startPrank(from);

    uint256 baycId = bayc.totalSupply();
    bayc.mint(from);

    (uint256 omnicastId, uint256 xp) = meditation.perform{value: value}(
      address(bayc),
      baycId
    );

    assertEq(omnicast.tokenURI(omnicastId), bayc.tokenURI(baycId));
    assertEq(omnicast.ownerOf(omnicastId), from);
    assertEq(xp, meditation.previewEDN(value));

    hevm.stopPrank();
  }
}
