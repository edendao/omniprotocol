// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Stewarded} from "./mixins/Stewarded.sol";
import {EdenDaoNS} from "./mixins/EdenDaoNS.sol";
import {ERC721Soulbound} from "./mixins/ERC721Soulbound.sol";
import {OmniTokenURI} from "./mixins/OmniTokenURI.sol";

// ======================================================
// Passport is your on-chain identity in omni-chain space
// ======================================================
contract Passport is ERC721Soulbound, Stewarded, OmniTokenURI, EdenDaoNS {
  string public name;
  string public symbol;

  constructor(address _steward, address _omnicast) {
    __initStewarded(_steward);
    __initOmniTokenURI(_omnicast);

    setNameAndSymbol("Eden Dao Passport", "DAO PASS");
  }

  event SetNameAndSymbol(string name, string symbol);

  function setNameAndSymbol(string memory _name, string memory _symbol)
    public
    requiresAuth
  {
    name = _name;
    symbol = _symbol;

    emit SetNameAndSymbol(_name, _symbol);
  }

  mapping(uint256 => address) private _ownerOf;

  function ownerOf(uint256 id) public view returns (address account) {
    require((account = _ownerOf[id]) != address(0), "NOT_MINTED");
  }

  function balanceOf(address account) public view returns (uint256) {
    return _ownerOf[idOf(account)] == address(0) ? 0 : 1;
  }

  function _mint(address to) internal returns (uint256 id) {
    id = idOf(to);

    if (_ownerOf[id] == address(0)) {
      _ownerOf[id] = to;
      emit Transfer(address(0), to, id);
    }
  }

  function mint(address to) external payable requiresAuth returns (uint256) {
    return _mint(to);
  }

  function mint() public payable returns (uint256) {
    require(msg.value >= 0.025 ether, "INVALID_MINT");
    return _mint(msg.sender);
  }

  receive() external payable {
    mint();
  }
}
