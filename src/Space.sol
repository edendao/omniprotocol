// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC721} from "@solmate/tokens/ERC721.sol";

import {IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

import {EdenDaoNS} from "@protocol/mixins/EdenDaoNS.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

contract Space is Omnichain, ERC721, EdenDaoNS {
  IOmnicast public immutable omnicast;
  uint16 public primaryChainId;

  constructor(
    address _comptroller,
    address _lzEndpoint,
    address _omnicast,
    uint16 _primaryChainId
  ) ERC721("Eden Dao Space", "DAO SPACE") {
    _setComptroller(_comptroller);
    _setLayerZeroEndpoint(_lzEndpoint);

    omnicast = IOmnicast(_omnicast);
    primaryChainId = _primaryChainId;
  }

  function mint(address to, string memory name)
    external
    requiresAuth
    returns (uint256 id)
  {
    id = idOf(name);
    _mint(to, id);
  }

  mapping(address => uint256) public countRegisteredBy;

  function mint(string memory name) public payable returns (uint256 id) {
    // solhint-disable-next-line avoid-tx-origin
    require(msg.sender == tx.origin, "Space: NO_SPOOFING");
    uint256 mints = countRegisteredBy[msg.sender];
    require(
      primaryChainId == block.chainid &&
        mints < 10 &&
        msg.value >= (mints + 1) * 0.05 ether,
      "Space: INVALID_MINT"
    );
    countRegisteredBy[msg.sender] = mints + 1;

    id = idOf(name);
    _mint(msg.sender, id);
  }

  // ==============================
  // ========= TOKEN URI ==========
  // ==============================
  mapping(uint256 => string) private _tokenURI;

  function tokenURI(uint256 id) public view override returns (string memory) {
    return string(omnicast.readMessage(id, idOf("tokenuri")));
  }

  // ======================
  // ====== EIP-2981 ======
  // ======================
  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 10) / 100);
  }

  // =========================
  // ======= OMNITOKEN =======
  // =========================
  function sendFrom(
    address from,
    uint16 toChainId,
    bytes memory toAddressB,
    uint256 id,
    address,
    address lzPaymentAddress,
    bytes memory lzAdapterParams
  ) external payable {
    require(msg.sender == from && from == ownerOf(id), "Space: UNAUTHORIZED");

    _burn(id);

    lzSend(
      toChainId,
      abi.encode(toAddressB, id),
      lzPaymentAddress,
      lzAdapterParams
    );
  }

  function receiveMessage(
    uint16,
    bytes calldata,
    uint64,
    bytes calldata payload
  ) internal override {
    (bytes memory toAddressB, uint256 id) = abi.decode(
      payload,
      (bytes, uint256)
    );

    _mint(addressFromPackedBytes(toAddressB), id);
  }
}
