// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

import {ERC721Soulbound} from "@protocol/mixins/ERC721Soulbound.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {EdenDaoNS} from "@protocol/mixins/EdenDaoNS.sol";

// ======================================================
// Passport is your on-chain identity in omni-chain space
// ======================================================
contract Passport is ERC721Soulbound, Comptrolled, EdenDaoNS {
  IOmnicast public omnicast;

  string public name = "Eden Dao Passport";
  string public symbol = "DAO PASS";

  mapping(uint256 => address) public ownerOf;

  constructor(address _comptroller, address _omnicast) {
    __initComptrolled(_comptroller);

    emit SetMeta(name, symbol);

    omnicast = IOmnicast(_omnicast);
  }

  event SetMeta(string name, string symbol);

  function setMeta(string memory _name, string memory _symbol)
    external
    requiresAuth
  {
    name = _name;
    symbol = _symbol;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return ownerOf[idOf(owner)] == address(0) ? 0 : 1;
  }

  function tokenURI(uint256 id) public view returns (string memory) {
    return string(omnicast.readMessage(id, idOf("tokenuri")));
  }

  function _mint(address to, uint256 id) internal {
    if (ownerOf[id] == address(0)) {
      ownerOf[id] = to;
      emit Transfer(address(0), to, id);
    }
  }

  function mint(address to) public payable returns (uint256 id) {
    require(msg.value >= 0.01 ether, "Passport: INVALID_MINT");
    id = idOf(to);
    _mint(to, id);
  }

  function mint() public payable returns (uint256) {
    return mint(msg.sender);
  }

  receive() external payable {
    mint(msg.sender);
  }
}
