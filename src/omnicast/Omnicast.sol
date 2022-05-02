// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721} from "@boring/interfaces/IERC721.sol";

import {IOmninote} from "@protocol/interfaces/IOmninote.sol";
import {IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

import {EdenDaoNS} from "@protocol/mixins/EdenDaoNS.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";

contract Omnicast is Omnichain, IOmnicast, EdenDaoNS {
  address public space;
  address public passport;

  constructor(address _lzEndpoint, address _comptroller) {
    __initOmnichain(_lzEndpoint);
    __initComptrolled(_comptroller);
  }

  function setContracts(address _space, address _passport)
    external
    requiresAuth
  {
    space = _space;
    passport = _passport;
  }

  // =====================================
  // ===== OMNICAST MESSAGING LAYER ======
  // =====================================
  function idOf(address account) public pure returns (uint256 id) {
    id = uint256(uint160(account));
  }

  function idOf(string memory name) public pure returns (uint256 id) {
    id = namehash(name);
    require(id > type(uint160).max, "Space: RESERVED_SPACE");
  }

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

  function receivedMessagesCount(uint256 receiverId, uint256 senderId)
    public
    view
    returns (uint256)
  {
    return receivedMessages[receiverId][senderId].length;
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

  function estimateLayerZeroGas(
    uint16 toChainId,
    bytes calldata payload,
    bool useZRO,
    bytes calldata adapterParams
  ) public view returns (uint256, uint256) {
    return
      lzEstimateSendGas(
        toChainId,
        abi.encode(uint256(0), uint256(0), payload),
        useZRO,
        adapterParams
      );
  }

  function writeMessage(
    uint256 toReceiverId,
    uint256 withSenderId,
    bytes memory payload,
    uint16 onChainId,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public payable {
    require(
      (msg.sender == IERC721(passport).ownerOf(toReceiverId) ||
        idOf(msg.sender) == withSenderId ||
        msg.sender == IERC721(space).ownerOf(withSenderId)),
      "Omnicast: UNAUTHORIZED"
    );

    uint64 nonce;
    if (onChainId == currentChainId) {
      receivedMessages[toReceiverId][withSenderId].push(payload);
      if (msg.value > 0) {
        payable(msg.sender).transfer(msg.value);
      }

      nonce = 0;
    } else {
      lzSend(
        onChainId,
        abi.encode(toReceiverId, withSenderId, payload),
        lzPaymentAddress,
        lzTransactionParams
      );

      nonce = lzEndpoint.getOutboundNonce(onChainId, address(this));
    }

    emit Message(onChainId, nonce, toReceiverId, withSenderId, payload);
  }
}
