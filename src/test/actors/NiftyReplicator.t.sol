// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { ERC721 } from "@rari-capital/solmate/tokens/ERC721.sol";

import { TestBase } from "@protocol/test/TestBase.sol";

import { NiftyReplicator } from "@protocol/actors/NiftyReplicator.sol";

contract NiftyNFT is ERC721 {
  constructor() ERC721("Nifty", "NFT") {
    this;
  }

  function mintTo(address to, uint256 id) public {
    _mint(to, id);
  }

  function tokenURI(uint256) public pure override returns (string memory) {
    return "nifty";
  }
}

contract NiftyReplicatorTest is TestBase {
  NiftyReplicator internal replicator =
    new NiftyReplicator(
      address(authority),
      address(0),
      address(passport),
      uint16(block.chainid)
    );

  NiftyNFT internal nifty = new NiftyNFT();

  address internal myAddress = address(this);

  function setUp() public {
    hevm.startPrank(owner);

    uint8 actor = 0;
    authority.setRoleCapability(actor, passport.ensureMintedTo.selector, true);
    authority.setRoleCapability(actor, passport.setTokenURI.selector, true);
    authority.setUserRole(address(replicator), actor, true);

    hevm.stopPrank();
  }

  function testReplicatorLock(uint256 tokenId) public {
    nifty.mintTo(myAddress, tokenId); // mint to self
    nifty.approve(address(replicator), tokenId);
    replicator.lock(address(nifty), tokenId);

    (
      uint16 chainid,
      address originalTokenAddress,
      uint256 originalTokenId,
      string memory originalURI
    ) = replicator.tokenOf(myAddress);

    assertEq(chainid, block.chainid);
    assertEq(originalTokenAddress, address(nifty));
    assertEq(originalTokenId, tokenId);
    assertEq(originalURI, nifty.tokenURI(tokenId));
    assertEq(nifty.balanceOf(address(replicator)), 1);
  }

  // function testReplicatorRelease() public {}
}
