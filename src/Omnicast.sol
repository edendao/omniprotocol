// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721TokenReceiver} from "@boring/interfaces/IERC721TokenReceiver.sol";
import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";
import {BoringAddress} from "@boring/libraries/BoringAddress.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {Soulbound, Immovable} from "@protocol/mixins/Soulbound.sol";

/*
 * An Omnicast is your cross-chain identity for the future.
 */
contract Omnicast is IERC721, IERC721Metadata, Omnichain, Pausable, Soulbound {
  string public constant name = "Eden Dao Omnicast";
  string public constant symbol = "OMNICAST";

  IERC721 internal channel;

  constructor(
    address _authority,
    address _layerZeroEndpoint,
    address _channel
  ) Omnichain(_authority, _layerZeroEndpoint) {
    channel = IERC721(_channel);
  }

  // Every address maps deterministically to a uint256
  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  function addressOf(uint256 id) public pure returns (address) {
    return address(uint160(id));
  }

  // Every address can only have one
  function balanceOf(address a) public view returns (uint256) {
    return ownerOf[idOf(a)] == address(0) ? 0 : 1;
  }

  // Owner is unset if not minted
  mapping(uint256 => address) public ownerOf;

  function mintTo(address to) public returns (uint256) {
    return _mintTo(to, idOf(to));
  }

  // Helper
  function _mintTo(address to, uint256 omnicastId) private returns (uint256) {
    require(ownerOf[omnicastId] == address(0), "Omnicast: NOT_AVAILABLE");

    ownerOf[omnicastId] = to;
    emit Transfer(address(0), to, omnicastId);

    return omnicastId;
  }

  // =======================================
  // ======== Messaging Layer =========
  // =======================================

  // On-chain data (myOmnicastId => senderOmnicastId => data)
  mapping(uint256 => mapping(uint256 => bytes)) public lastMessageOf;

  uint256 public constant NAME_CHANNEL = (
    0x5390756d6822bfddf4c057851c400cc27c97960f67128fa42a6d838b35584b8c
  ); // name.eden.dao

  uint256 public constant TOKENURI_CHANNEL = (
    0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f
  ); // tokenuri.eden.dao

  function nameOf(uint256 omnicastId) public view returns (string memory) {
    return string(lastMessageOf[omnicastId][NAME_CHANNEL]);
  }

  function tokenURI(uint256 omnicastId) public view returns (string memory) {
    return string(lastMessageOf[omnicastId][TOKENURI_CHANNEL]);
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

  function tryCallMessage(uint256 channelId, bytes memory message) private {
    address omnicastAddress = addressOf(channelId);
    if (BoringAddress.isContract(omnicastAddress)) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool ok, bytes memory data) = omnicastAddress.call{value: msg.value}(
        message
      );
      require(ok, string(data));
    }
  }

  function sendMessage(
    uint16 toChainId,
    uint256 omnicastId,
    uint256 channelId,
    bytes memory message
  ) external payable whenNotPaused {
    require(
      (msg.sender == ownerOf[omnicastId] ||
        channelId == idOf(msg.sender) ||
        msg.sender == channel.ownerOf(channelId)),
      "Omnicast: UNAUTHORIZED_CHANNEL"
    );

    if (toChainId == currentChainId) {
      lastMessageOf[omnicastId][channelId] = message;
      tryCallMessage(channelId, message);
    } else {
      bytes memory data = abi.encode(omnicastId, channelId, message);
      (uint256 nativeFee, ) = estimateLzSendGas(toChainId, data, false, "");
      require(msg.value >= nativeFee, "Omnicast: INSUFFICIENT_SEND_VALUE");

      // solhint-disable-next-line check-send-result
      lzEndpoint.send{value: msg.value}(
        toChainId,
        remoteContracts[toChainId],
        data,
        payable(msg.sender),
        address(comptroller()),
        ""
      );
    }

    emit Message(toChainId, omnicastId, channelId, message);
  }

  function onMessage(
    uint16, // fromChainId
    bytes calldata, // fromContractAddress,
    uint64, // nonce
    bytes memory payload
  ) internal override {
    (uint256 omnicastId, uint256 channelId, bytes memory message) = abi.decode(
      payload,
      (uint256, uint256, bytes)
    );

    lastMessageOf[omnicastId][channelId] = message;
    tryCallMessage(channelId, message);

    emit Message(currentChainId, omnicastId, channelId, message);
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
