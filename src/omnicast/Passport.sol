// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {ERC721Soulbound} from "@protocol/mixins/ERC721Soulbound.sol";
import {Omninote} from "@protocol/mixins/Omninote.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

// ======================================================
// Passport is your on-chain identity in omni-chain space
// ======================================================
contract Passport is Omninote, Pausable, ERC721Soulbound {
  IOmnicast public immutable omnicast;

  string public name = "Eden Dao Passport";
  string public symbol = "DAO PASS";

  mapping(uint256 => address) public ownerOf;

  constructor(address _comptroller, address _omnicast)
    Comptrolled(_comptroller)
  {
    omnicast = IOmnicast(_omnicast);
  }

  function balanceOf(address owner) public view returns (uint256) {
    return ownerOf[omnicast.idOf(owner)] == address(0) ? 0 : 1;
  }

  function tokenURI(uint256 id) public view returns (string memory) {
    return string(omnicast.readMessage(id, omnicast.idOf("tokenuri")));
  }

  // User mints
  function mint() public payable returns (uint256) {
    require(msg.value >= 0.01 ether, "Passport: INVALID_MINT");
    uint256 id = omnicast.idOf(msg.sender);
    _mint(msg.sender, id);
    return id;
  }

  receive() external payable override {
    mint();
  }

  // Omnibridge mints
  function mintTo(address to, uint256 id)
    public
    override
    requiresAuth
    returns (uint256)
  {
    require(id == omnicast.idOf(to), "Passport: INVALID_MINT");
    _mint(to, id);
    return id;
  }

  // Cannot be burned
  function burnFrom(address, uint256) public pure override returns (uint256) {
    return 0;
  }

  function _mint(address to, uint256 id) internal whenNotPaused {
    if (ownerOf[id] == address(0)) {
      ownerOf[id] = to;
      emit Transfer(address(0), to, id);
    }
  }
}
