// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721} from "@boring/interfaces/IERC721.sol";

import {IOmnicaster} from "@protocol/interfaces/IOmnicaster.sol";
import {EdenDaoNS} from "@protocol/libraries/EdenDaoNS.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

interface IOmnichannel {
  function ownerAddressOf(uint256 channelId) external view returns (address);
}

// Only for use with Omnicast
abstract contract Omnicaster is IOmnicaster, Omnichain, Pausable {
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
    uint16 chainId,
    uint64 nonce,
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
    uint64 nonce,
    bytes memory payload
  ) internal override whenNotPaused {
    (uint256 receiverId, uint256 senderId, bytes memory data) = abi.decode(
      payload,
      (uint256, uint256, bytes)
    );

    receivedMessages[receiverId][senderId].push(data);
    emit Message(currentChainId, nonce, receiverId, senderId, data);
  }

  function readMessage(uint256 receiverId, uint256 senderId)
    public
    view
    returns (bytes memory)
  {
    bytes[] memory messages = receivedMessages[receiverId][senderId];
    return messages[messages.length - 1];
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
        (toReceiverId > type(uint160).max &&
          msg.sender == omnichannel.ownerOf(toReceiverId))),
      "Omnicaster: UNAUTHORIZED_CHANNEL"
    );

    if (toChainId == currentChainId) {
      receivedMessages[toReceiverId][withSenderId].push(payload);
      if (msg.value != 0) {
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
