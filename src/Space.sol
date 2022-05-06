// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "@solmate/tokens/ERC721.sol";

import {IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omninote} from "@protocol/mixins/Omninote.sol";

contract Space is Omninote, ERC721 {
  IOmnicast public immutable omnicast;
  uint16 public primaryChainId;

  constructor(
    address _comptroller,
    address _omnicast,
    uint16 _primaryChainId
  ) ERC721("Eden Dao Space", "DAO SPACE") {
    __initComptrolled(_comptroller);
    omnicast = IOmnicast(_omnicast);
    primaryChainId = _primaryChainId;
    uint256[10] memory premint = [
      omnicast.idOf("my"),
      omnicast.idOf("profile"),
      omnicast.idOf("app"),
      omnicast.idOf("name"),
      omnicast.idOf("tokenuri"),
      omnicast.idOf("terexitarius"),
      omnicast.idOf("gitcoin"),
      omnicast.idOf("station"),
      omnicast.idOf("refi"),
      omnicast.idOf("space")
    ];
    for (uint256 i = 0; i < premint.length; i++) {
      _mint(comptrollerAddress(), premint[i]);
    }
  }

  mapping(address => uint256) public spacesRegisteredBy;

  function mint(string memory name) public payable returns (uint256) {
    uint256 mints = spacesRegisteredBy[msg.sender];
    require(
      primaryChainId == block.chainid &&
        mints < 10 &&
        msg.value >= (mints + 1) * 0.05 ether,
      "Space: INVALID_MINT"
    );
    spacesRegisteredBy[msg.sender] = mints + 1;

    uint256 id = omnicast.idOf(name);
    _mint(msg.sender, id);

    return id;
  }

  // ==============================
  // ========= TOKEN URI ==========
  // ==============================
  mapping(uint256 => string) private _tokenURI;

  function tokenURI(uint256 id) public view override returns (string memory) {
    return string(omnicast.readMessage(id, omnicast.idOf("tokenuri")));
  }

  // ======================
  // ====== EIP-2981 ======
  // ======================
  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (comptrollerAddress(), (salePrice * 10) / 100);
  }

  // ==========================
  // ======= OMNIBRIDGE =======
  // ==========================
  function mintTo(address to, uint256 id) public override requiresAuth {
    require(id > type(uint160).max, "Space: RESERVED_SPACE");
    _mint(to, id);
  }

  function burnFrom(address, uint256 id) public override requiresAuth {
    _burn(id);
  }
}
