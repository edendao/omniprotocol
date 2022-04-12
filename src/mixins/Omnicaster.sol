// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

import {Omnichannel} from "@protocol/Omnichannel.sol";

import {IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

contract Omnicaster is IOmnicast, Omnichain, Pausable {
  Omnichannel internal omnichannel;

  constructor(
    address _comptroller,
    address _layerZeroEndpoint,
    address _omnichannel
  ) Omnichain(_comptroller, _layerZeroEndpoint) {
    omnichannel = Omnichannel(_omnichannel);
  }

  // Every address maps deterministically to a uint256
  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  // =====================================
  // ===== OMNICAST MESSAGING LAYER ======
  // =====================================
  event Message(
    uint256 indexed chainId,
    uint256 indexed omnicastId,
    uint256 indexed channelId,
    bytes data
  );

  // (receiverId => senderId => data[])
  mapping(uint256 => mapping(uint256 => bytes[])) public receivedMessages;

  function receivedMessagesCount(
    uint256 recieverCasterId,
    uint256 senderCasterId
  ) public view returns (uint256) {
    return receivedMessages[recieverCasterId][senderCasterId].length;
  }

  function readMessage(uint256 receiverCasterId, uint256 senderCasterId)
    public
    view
    returns (bytes memory)
  {
    bytes[] memory messages = receivedMessages[receiverCasterId][
      senderCasterId
    ];
    return messages.length == 0 ? bytes("") : messages[messages.length - 1];
  }

  // Maximum control — specify the omnicast and omnichannel by ID
  function sendMessage(
    uint16 toChainId,
    uint256 toReceiverId,
    uint256 withCasterId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public payable whenNotPaused {
    require(
      (msg.sender == address(uint160(toReceiverId)) ||
        withCasterId == idOf(msg.sender) ||
        msg.sender == omnichannel.ownerOf(withCasterId)),
      "Omnicaster: UNAUTHORIZED_CHANNEL"
    );

    if (toChainId == currentChainId) {
      receivedMessages[toReceiverId][withCasterId].push(payload);
    } else {
      lzSend(
        toChainId,
        abi.encode(toReceiverId, withCasterId, payload),
        lzPaymentAddress,
        lzTransactionParams
      );
    }

    emit Message(toChainId, toReceiverId, withCasterId, payload);
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

    receivedMessages[omnicastId][channelId].push(message);
    emit Message(currentChainId, omnicastId, channelId, message);
  }
}
