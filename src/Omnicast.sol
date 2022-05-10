// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmnicast} from "@protocol/interfaces/IOmnicast.sol";

import {EdenDaoNS} from "@protocol/mixins/EdenDaoNS.sol";
import {Initializable} from "@protocol/mixins/Initializable.sol";
import {Multicallable} from "@protocol/mixins/Multicallable.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

interface Ownable {
  function ownerOf(uint256 id) external view returns (address);
}

contract Omnicast is
  PublicGood,
  Comptrolled,
  IOmnicast,
  Omnichain,
  Multicallable,
  Initializable,
  EdenDaoNS
{
  uint16 public immutable currentChainId;
  uint64 public nonce;

  constructor(
    address _lzEndpoint,
    address _comptroller,
    uint16 _currentChainId
  ) {
    __initComptrolled(_comptroller);
    __initOmnichain(_lzEndpoint);

    currentChainId = _currentChainId;
  }

  address public space;
  address public passport;

  function initialize(address _beneficiary, bytes memory _params)
    external
    override
    initializer
  {
    __initPublicGood(_beneficiary);

    (address _space, address _passport) = abi.decode(
      _params,
      (address, address)
    );

    space = _space;
    passport = _passport;
  }

  // =====================================
  // ===== OMNICAST MESSAGING LAYER ======
  // =====================================
  // (receiverId => senderId => (uint64 nonce, bytes payload)[])
  mapping(uint256 => mapping(uint256 => bytes[])) public receivedMessages;

  function readMessage(uint256 receiverId, uint256 senderId)
    public
    view
    returns (bytes memory)
  {
    bytes[] memory messages = receivedMessages[receiverId][senderId];
    (, bytes memory payload) = abi.decode(
      messages[messages.length - 1],
      (uint64, bytes)
    );
    return payload;
  }

  function readMessage(
    uint256 receiverId,
    uint256 senderId,
    uint64 withNonce
  ) public view returns (bytes memory) {
    bytes[] memory messages = receivedMessages[receiverId][senderId];
    for (uint256 i = messages.length - 1; i >= 0; i--) {
      (uint64 msgNonce, bytes memory payload) = abi.decode(
        messages[messages.length - 1],
        (uint64, bytes)
      );
      if (msgNonce == withNonce) {
        return payload;
      }
    }
    return bytes("");
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
    uint64 msgNonce,
    bytes calldata payload
  ) internal override {
    (uint256 receiverId, uint256 senderId, bytes memory data) = abi.decode(
      payload,
      (uint256, uint256, bytes)
    );

    receivedMessages[receiverId][senderId].push(abi.encode(msgNonce, data));
    emit Message(currentChainId, msgNonce, receiverId, senderId, data);
  }

  function estimateWriteFee(
    uint16 toChainId,
    bytes calldata data,
    bool useZRO,
    bytes calldata adapterParams
  ) public view returns (uint256 nativeFee, uint256 zroFee) {
    (nativeFee, zroFee) = lzEndpoint.estimateFees(
      toChainId,
      address(this),
      abi.encode(uint256(0), uint256(0), data),
      useZRO,
      adapterParams
    );
  }

  function canWriteMessage(
    address writer,
    uint256 toReceiverId,
    uint256 withSenderId
  ) public view returns (bool) {
    if (uint256(uint160(writer)) == toReceiverId) {
      return true;
    }

    if (withSenderId > type(uint160).max) {
      try Ownable(space).ownerOf(withSenderId) returns (address owner) {
        return owner == writer;
      } catch {
        return false;
      }
    } else {
      try Ownable(passport).ownerOf(withSenderId) returns (address owner) {
        return owner == writer;
      } catch {
        return false;
      }
    }
  }

  function writeMessage(
    uint256 toReceiverId,
    uint256 withSenderId,
    bytes memory data,
    uint16 onChainId,
    address lzPaymentAddress,
    bytes calldata lzAdapterParams
  ) public payable {
    require(
      canWriteMessage(msg.sender, toReceiverId, withSenderId),
      "Omnicast: UNAUTHORIZED"
    );

    if (onChainId == currentChainId) {
      uint64 msgNonce = nonce++;
      receivedMessages[toReceiverId][withSenderId].push(
        abi.encode(msgNonce, data)
      );

      emit Message(onChainId, msgNonce, toReceiverId, withSenderId, data);
    } else {
      lzSend(
        onChainId,
        abi.encode(toReceiverId, withSenderId, data),
        lzPaymentAddress,
        lzAdapterParams
      );

      emit Message(
        onChainId,
        lzEndpoint.getOutboundNonce(onChainId, address(this)),
        toReceiverId,
        withSenderId,
        data
      );
    }
  }
}
