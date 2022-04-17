// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721, IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

import {EdenDaoNS} from "@protocol/mixins/EdenDaoNS.sol";
import {ERC721Soulbound, Immovable} from "@protocol/mixins/ERC721Soulbound.sol";
import {Multicallable} from "@protocol/mixins/Multicallable.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";

// ======================================================
// Omnicast is your on-chain identity in omni-chain space
// ======================================================
contract Omnicast is
  ERC721Soulbound,
  IOmnicast,
  Omnichain,
  Multicallable,
  EdenDaoNS
{
  string public constant name = "Eden Dao Omnicast";
  string public constant symbol = "OMNICAST";
  mapping(uint256 => address) public ownerOf;

  IERC721 internal omnichannel;

  constructor(
    address _comptroller,
    address _layerZeroEndpoint,
    address _omnichannel
  ) Omnichain(_comptroller, _layerZeroEndpoint) {
    omnichannel = IERC721(_omnichannel);
  }

  // ==================================
  // ========== IOmnichannel ==========
  // ==================================
  function idOf(address account) public pure returns (uint256) {
    return uint256(uint160(account));
  }

  function idOf(string memory label) public pure returns (uint256) {
    return namehash(label);
  }

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

  uint256 public immutable nameChannel = idOf("name");
  uint256 public immutable tokenURIChannel = idOf("tokenuri");

  function nameOf(uint256 omnicastId) public view returns (string memory) {
    return string(readMessage(omnicastId, nameChannel));
  }

  function tokenURI(uint256 omnicastId) public view returns (string memory) {
    return string(readMessage(omnicastId, tokenURIChannel));
  }

  function setTokenURI(uint256 omnicastId, string memory uri) public {
    sendMessage(
      currentChainId,
      omnicastId,
      tokenURIChannel,
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
      tokenURIChannel,
      bytes(uri),
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  // =====================================
  // ===== OMNICAST MESSAGING LAYER ======
  // =====================================
  event Message(
    uint16 indexed chainId,
    uint64 nonce,
    uint256 indexed receiverId,
    uint256 indexed senderId,
    bytes data
  );

  // (receiverId => senderId => data[])
  mapping(uint256 => mapping(uint256 => bytes[])) public receivedMessages;

  function readMessage(uint256 receiverId, uint256 senderId)
    public
    view
    returns (bytes memory)
  {
    bytes[] memory messages = receivedMessages[receiverId][senderId];
    return messages[messages.length - 1];
  }

  function receivedMessagesCount(
    uint256 recieverCasterId,
    uint256 senderCasterId
  ) public view returns (uint256) {
    return receivedMessages[recieverCasterId][senderCasterId].length;
  }

  function receiveMessage(
    uint16, // fromChainId
    bytes calldata, // fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal override {
    (uint256 receiverId, uint256 senderId, bytes memory data) = abi.decode(
      payload,
      (uint256, uint256, bytes)
    );

    receivedMessages[receiverId][senderId].push(data);
    emit Message(currentChainId, nonce, receiverId, senderId, data);
  }

  function estimateSendFee(
    uint16 toChainId,
    uint256 toReceiverId,
    uint256 withSenderId,
    bytes calldata payload,
    bool useZRO,
    bytes calldata adapterParams
  ) public view returns (uint256, uint256) {
    return
      lzEstimateSendGas(
        toChainId,
        abi.encode(toReceiverId, withSenderId, payload),
        useZRO,
        adapterParams
      );
  }

  function sendMessage(
    uint16 toChainId,
    uint256 toReceiverId,
    uint256 withSenderId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public payable {
    require(
      (msg.sender == address(uint160(toReceiverId)) ||
        withSenderId == idOf(msg.sender) ||
        (toReceiverId > type(uint160).max &&
          msg.sender == omnichannel.ownerOf(toReceiverId))),
      "Omnicaster: UNAUTHORIZED_CHANNEL"
    );

    if (toChainId == currentChainId) {
      receivedMessages[toReceiverId][withSenderId].push(payload);
      if (msg.value > 0) {
        payable(msg.sender).transfer(msg.value);
      }
    } else {
      lzSend(
        toChainId,
        abi.encode(toReceiverId, withSenderId, payload),
        lzPaymentAddress,
        lzTransactionParams
      );
    }

    emit Message(
      toChainId,
      lzEndpoint.getOutboundNonce(toChainId, address(this)),
      toReceiverId,
      withSenderId,
      payload
    );
  }
}
