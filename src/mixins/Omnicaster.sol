// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721} from "@boring/interfaces/IERC721.sol";

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

import {IOmnicaster} from "@protocol/interfaces/IOmnicaster.sol";
import {EdenDaoNS} from "@protocol/libraries/EdenDaoNS.sol";

contract Omnicaster is IOmnicaster, Omnichain, Pausable {
  IERC721 internal omnichannel;

  constructor(
    address _comptroller,
    address _layerZeroEndpoint,
    address _omnichannel
  ) Omnichain(_comptroller, _layerZeroEndpoint) {
    omnichannel = IERC721(_omnichannel);
  }

  function idOf(address to) public pure returns (uint256) {
    return uint256(uint160(to));
  }

  function idOf(string memory name) public pure returns (uint256) {
    return EdenDaoNS.namehash(name);
  }

  // =====================================
  // ===== OMNICAST MESSAGING LAYER ======
  // =====================================
  event Message(
    uint256 indexed chainId,
    uint256 indexed receiverId,
    uint256 indexed senderId,
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

  function receiveMessage(
    uint16, // fromChainId
    bytes calldata, // fromContractAddress,
    uint64, // nonce
    bytes memory data
  ) internal override {
    (uint256 receiverId, uint256 senderId, bytes memory message) = abi.decode(
      data,
      (uint256, uint256, bytes)
    );

    receivedMessages[receiverId][senderId].push(message);
    emit Message(currentChainId, receiverId, senderId, message);
  }

  function readMessage(uint256 receiverId, uint256 senderId)
    public
    view
    returns (bytes memory)
  {
    bytes[] memory messages = receivedMessages[receiverId][senderId];
    return messages.length == 0 ? bytes("") : messages[messages.length - 1];
  }

  function sendMessage(
    uint16 toChainId,
    uint256 toReceiverId,
    uint256 withSenderId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public payable whenNotPaused {
    require(
      (msg.sender == address(uint160(toReceiverId)) ||
        withSenderId == idOf(msg.sender) ||
        msg.sender == omnichannel.ownerOf(withSenderId)),
      "Omnicaster: UNAUTHORIZED_CHANNEL"
    );

    if (toChainId == currentChainId) {
      receivedMessages[toReceiverId][withSenderId].push(payload);
    } else {
      lzSend(
        toChainId,
        abi.encode(toReceiverId, withSenderId, payload),
        lzPaymentAddress,
        lzTransactionParams
      );
    }

    emit Message(toChainId, toReceiverId, withSenderId, payload);
  }
}
