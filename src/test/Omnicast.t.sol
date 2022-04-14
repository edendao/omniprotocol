// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, console} from "@protocol/test/ChainEnvironment.t.sol";

contract OmnicastTest is ChainEnvironmentTest {
  function testMintGas() public {
    omnicast.mintTo(address(this));
  }

  function testMintTo(address to) public {
    hevm.assume(to != address(0));

    uint256 omnicastId = omnicast.mintTo(to);

    assertEq(omnicast.balanceOf(to), 1);
    assertEq(omnicast.ownerOf(omnicastId), to);
  }

  function testMintNotAvailable(address to) public {
    hevm.assume(to != address(0));

    omnicast.mintTo(to);
    hevm.expectRevert("Omnicast: NOT_AVAILABLE");
    omnicast.mintTo(to);
  }

  function testMintRequiresAuth(address caller) public {
    hevm.assume(caller != address(0) && caller != address(this));

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    omnicast.mintTo(caller);
  }

  function testSettingTokenURI(address caller, string memory uri) public {
    hevm.assume(caller != address(0) && caller != address(this));

    uint256 omnicastId = omnicast.mintTo(caller);

    hevm.prank(caller);
    omnicast.setTokenURI(omnicastId, uri);

    assertEq(uri, omnicast.tokenURI(omnicastId));
  }

  function testSettingUnmintedTokenURI(address caller, string memory uri)
    public
  {
    hevm.assume(caller != address(0) && caller != address(this));

    uint256 omnicastId = omnicast.mintTo(caller);

    hevm.expectRevert("Omnicaster: UNAUTHORIZED_CHANNEL");
    hevm.prank(caller);
    omnicast.setTokenURI(omnicastId + 1, uri);
  }

  function testSettingOtherTokenURI(address caller, string memory uri) public {
    hevm.assume(caller != address(0) && caller != address(this));

    uint256 myOmnicastId = omnicast.mintTo(address(this));

    hevm.expectRevert("Omnicaster: UNAUTHORIZED_CHANNEL");
    hevm.prank(caller);
    omnicast.setTokenURI(myOmnicastId, uri);
  }
}
