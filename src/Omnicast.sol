// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721TokenReceiver} from "@boring/interfaces/IERC721TokenReceiver.sol";
import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Soulbound, Immovable} from "@protocol/mixins/Soulbound.sol";
import {Omnicaster} from "@protocol/mixins/Omnicaster.sol";

// ===================================================
// An Omnicast is your on-chain identity in omnispace.
// ===================================================
contract Omnicast is IERC721, IERC721Metadata, Omnicaster, Soulbound {
  string public constant name = "Eden Dao Omnicast";
  string public constant symbol = "OMNICAST";
  mapping(uint256 => address) public ownerOf;

  constructor(
    address _comptroller,
    address _layerZeroEndpoint,
    address _omnichannel
  ) Omnicaster(_comptroller, _layerZeroEndpoint, _omnichannel) {
    this;
  }

  // Every address can only have one
  function balanceOf(address a) public view returns (uint256) {
    return ownerOf[idOf(a)] == address(0) ? 0 : 1;
  }

  function mintTo(address to) external requiresAuth returns (uint256) {
    uint256 omnicastId = idOf(to);
    require(ownerOf[omnicastId] == address(0), "Omnicast: NOT_AVAILABLE");

    ownerOf[omnicastId] = to;
    emit Transfer(address(0), to, omnicastId);

    return omnicastId;
  }

  uint256 public constant NAME_CHANNEL = (
    0x5390756d6822bfddf4c057851c400cc27c97960f67128fa42a6d838b35584b8c
  ); // name.eden.dao

  uint256 public constant TOKENURI_CHANNEL = (
    0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f
  ); // tokenuri.eden.dao

  function nameOf(uint256 omnicastId) public view returns (string memory) {
    return string(readMessage(omnicastId, NAME_CHANNEL));
  }

  function tokenURI(uint256 omnicastId) public view returns (string memory) {
    return string(readMessage(omnicastId, TOKENURI_CHANNEL));
  }

  function setTokenURI(uint256 omnicastId, string memory uri) public {
    sendMessage(
      currentChainId,
      omnicastId,
      TOKENURI_CHANNEL,
      bytes(uri),
      address(0),
      ""
    );
  }

  function sendTokenURI(
    uint16 toChainId,
    uint256 omnicastId,
    string memory uri,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public {
    sendMessage(
      toChainId,
      omnicastId,
      TOKENURI_CHANNEL,
      bytes(uri),
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  // =================================
  // ============ IERC721 ============
  // =================================
  function approve(address, uint256) external payable {
    revert Immovable();
  }

  function setApprovalForAll(address, bool) external pure {
    revert Immovable();
  }

  function getApproved(uint256) external pure returns (address) {
    return address(0);
  }

  function isApprovedForAll(address, address) external pure returns (bool) {
    return false;
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public payable override(IERC721, Soulbound) {
    super.transferFrom(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public payable override(IERC721, Soulbound) {
    super.safeTransferFrom(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes calldata data
  ) public payable override(IERC721, Soulbound) {
    super.safeTransferFrom(from, to, id, data);
  }
}
