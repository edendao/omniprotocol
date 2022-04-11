// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721TokenReceiver} from "@boring/interfaces/IERC721TokenReceiver.sol";
import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";
import {BoringAddress} from "@boring/libraries/BoringAddress.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Metta} from "@protocol/mixins/Metta.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {Soulbound, Immovable} from "@protocol/mixins/Soulbound.sol";

/*
 * An Omnicast is your cross-chain identity for the future.
 */
contract Omnicast is
  IERC721,
  IERC721Metadata,
  Omnichain,
  Metta,
  Pausable,
  Soulbound
{
  string public constant name = "Eden Dao Omnicast";
  string public constant symbol = "OMNICAST";

  IERC721 internal channel;

  constructor(
    address _authority,
    address _layerZeroEndpoint,
    address _edn,
    address _channel
  ) Omnichain(_authority, _layerZeroEndpoint) Metta(_edn) {
    channel = IERC721(_channel);
  }

  // Every address maps deterministically to a uint256
  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  // Every address can only have one
  function balanceOf(address a) public view returns (uint256) {
    return ownerOf[idOf(a)] == address(0) ? 0 : 1;
  }

  // Owner is unset if not minted
  mapping(uint256 => address) public ownerOf;

  function mint() public payable returns (uint256, uint256) {
    return mintTo(msg.sender);
  }

  function mintTo(address to) public payable returns (uint256, uint256) {
    require(msg.value >= 0.025 ether, "Omnicast: INSUFFICIENT_VALUE");
    uint256 omnicastId = uint256(uint160(to));
    require(ownerOf[omnicastId] == address(0), "Omnicast: NOT_AVAILABLE");

    ownerOf[omnicastId] = to;
    emit Transfer(address(0), to, omnicastId);

    return (omnicastId, edn.mintTo(msg.sender, previewEDN(msg.value)));
  }

  // =======================================
  // ======== Messaging Layer =========
  // =======================================

  // On-chain data (myOmnicastId => onChannelId => data)
  mapping(uint256 => mapping(uint256 => bytes)) public readMessage;

  uint256 public constant NAME_CHANNEL = (
    0x5390756d6822bfddf4c057851c400cc27c97960f67128fa42a6d838b35584b8c
  ); // name.eden.dao

  uint256 public constant TOKENURI_CHANNEL = (
    0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f
  ); // tokenuri.eden.dao

  function nameOf(uint256 omnicastId) public view returns (string memory) {
    return string(readMessage[omnicastId][NAME_CHANNEL]);
  }

  function tokenURI(uint256 omnicastId) public view returns (string memory) {
    return string(readMessage[omnicastId][TOKENURI_CHANNEL]);
  }

  // ===========================
  // ======== Omnichain ========
  // ===========================
  event Message(
    uint256 indexed chainId,
    uint256 indexed omnicastId,
    uint256 indexed channelId,
    bytes data
  );

  function readMessageFrom(address fromAddress)
    public
    view
    returns (bytes memory)
  {
    return readMessage[idOf(msg.sender)][idOf(fromAddress)];
  }

  function sendMessage(
    uint16 toChainId,
    address toAddress,
    bytes memory payload
  ) public payable {
    sendMessage(
      toChainId,
      uint256(uint160(toAddress)),
      idOf(msg.sender),
      payload
    );
  }

  function sendMessage(
    uint16 toChainId,
    uint256 toOmnicastId,
    uint256 onChannelId,
    bytes memory payload
  ) public payable whenNotPaused {
    require(
      (msg.sender == ownerOf[toOmnicastId] ||
        onChannelId == idOf(msg.sender) ||
        msg.sender == channel.ownerOf(onChannelId)),
      "Omnicast: UNAUTHORIZED_CHANNEL"
    );

    if (toChainId == currentChainId) {
      readMessage[toOmnicastId][onChannelId] = payload;
    } else {
      lzSend(toChainId, abi.encode(toOmnicastId, onChannelId, payload));
    }

    emit Message(toChainId, toOmnicastId, onChannelId, payload);
  }

  function receiveMessage(
    uint16, // fromChainId
    bytes calldata, // fromContractAddress,
    uint64, // nonce
    bytes memory data
  ) internal override {
    (uint256 omnicastId, uint256 channelId, bytes memory message) = abi.decode(
      data,
      (uint256, uint256, bytes)
    );

    readMessage[omnicastId][channelId] = message;

    emit Message(currentChainId, omnicastId, channelId, message);
  }

  // =====================
  // ====== IERC721 ======
  // =====================
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
