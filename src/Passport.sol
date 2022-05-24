// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Stewarded} from "@omniprotocol/mixins/Stewarded.sol";
import {EdenDaoNS} from "@omniprotocol/mixins/EdenDaoNS.sol";
import {ERC721Soulbound} from "@omniprotocol/mixins/ERC721Soulbound.sol";
import {OmniTokenURI} from "@omniprotocol/mixins/OmniTokenURI.sol";

// ======================================================
// Passport is your on-chain identity in omni-chain space
// ======================================================
contract Passport is ERC721Soulbound, Stewarded, OmniTokenURI, EdenDaoNS {
  string public name = "Eden Dao Passport";
  string public symbol = "DAO PASS";

  mapping(uint256 => address) private _ownerOf;

  constructor(address _steward, address _omnicast) {
    __initStewarded(_steward);
    __initOmniTokenURI(_omnicast);
  }

  function ownerOf(uint256 id) public view returns (address owner) {
    require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _ownerOf[idOf(owner)] == address(0) ? 0 : 1;
  }

  function mint(address to) public payable returns (uint256 id) {
    require(msg.value >= 0.01 ether, "INVALID_MINT");

    id = idOf(to);

    if (_ownerOf[id] == address(0)) {
      _ownerOf[id] = to;
      emit Transfer(address(0), to, id);
    }
  }

  function mint() public payable returns (uint256) {
    return mint(msg.sender);
  }

  receive() external payable {
    mint(msg.sender);
  }
}
