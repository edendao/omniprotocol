// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721TokenReceiver} from "@boring/interfaces/IERC721TokenReceiver.sol";
import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {Soulbound, Immovable} from "@protocol/mixins/Soulbound.sol";

import {Channel} from "./Channel.sol";

/*
 * A Passport is your cross-chain identity for the future.
 */
contract Passport is IERC721, IERC721Metadata, Omnichain, Pausable, Soulbound {
  string public constant name = "Eden Dao Passport";
  string public constant symbol = "DAO PASS";

  constructor(address _authority, address _layerZeroEndpoint)
    Omnichain(_authority, _layerZeroEndpoint)
  {
    this;
  }

  mapping(uint256 => address) public ownerOf; // unset if not minted

  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  function balanceOf(address a) public view returns (uint256) {
    return ownerOf[idOf(a)] == address(0) ? 0 : 1;
  }

  // Anyone can mint a passport for their address
  function findOrMintFor(address to) public returns (uint256 passportId) {
    passportId = idOf(to);

    if (ownerOf[passportId] == address(0)) {
      ownerOf[passportId] = to;
      emit Transfer(address(0), to, passportId);
    }
  }

  // ========================================
  // Data & Channel Layer
  // ========================================

  // On-chain data (tokenId => channelId => data)
  mapping(uint256 => mapping(uint256 => bytes)) public dataOf;

  uint256 public constant TOKENURI_CHANNEL = (
    0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f
  ); // tokenuri.eden.dao

  function tokenURI(uint256 passportId) public view returns (string memory) {
    return string(dataOf[passportId][TOKENURI_CHANNEL]);
  }

  // Token Channel is the name associated with your passport
  uint256 public constant PASSPORT_CHANNEL = (
    0x02dae9de41f5b412ce8d65c69e825802e5cfc0bb85d707c53c94e30d4ddd56d2
  ); // channel.eden.dao

  function fusedChannelOf(uint256 passportId)
    public
    view
    returns (uint256, string memory)
  {
    return abi.decode(dataOf[passportId][PASSPORT_CHANNEL], (uint256, string));
  }

  // ============================
  // ======== Data Layer ========
  // ============================
  event SendData(
    uint256 indexed toChainId,
    uint256 indexed passportId,
    uint256 indexed channelId,
    bytes data
  );

  function sendData(
    uint16 toChainId,
    uint256 passportId,
    uint256 channelId,
    bytes memory data,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable whenNotPaused {
    require(
      (msg.sender == ownerOf[passportId] || isAuthorized(msg.sender, msg.sig)),
      "Passport: UNAUTHORIZED"
    );

    if (toChainId == currentChainId) {
      dataOf[passportId][channelId] = data;
    } else {
      lzSend(
        toChainId,
        abi.encode(passportId, channelId, data),
        zroPaymentAddress,
        adapterParams
      );
    }

    emit SendData(toChainId, passportId, channelId, data);
  }

  // on receive lzSend from target chain
  function onReceive(
    uint16, // fromChainId
    bytes calldata, // fromContractAddress,
    uint64, // nonce
    bytes memory payload
  ) internal override {
    (uint256 passportId, uint256 channelId, bytes memory data) = abi.decode(
      payload,
      (uint256, uint256, bytes)
    );

    dataOf[passportId][channelId] = data;

    emit SendData(currentChainId, passportId, channelId, data);
  }

  // ===================
  // ===== IERC721 =====
  // ===================
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
