// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmnicast} from "./interfaces/IOmnicast.sol";

import {EdenDaoNS} from "./mixins/EdenDaoNS.sol";
import {Initializable} from "./mixins/Initializable.sol";
import {Multicallable} from "./mixins/Multicallable.sol";
import {Stewarded} from "./mixins/Stewarded.sol";
import {Omnichain} from "./mixins/Omnichain.sol";
import {PublicGood} from "./mixins/PublicGood.sol";

interface Ownable {
  function ownerOf(uint256 id) external view returns (address);
}

contract Omnicast is
  PublicGood,
  Stewarded,
  IOmnicast,
  Omnichain,
  Multicallable,
  Initializable,
  EdenDaoNS
{
  uint16 public immutable currentChainId;
  uint64 public nonce;

  constructor(
    address _steward,
    address _lzEndpoint,
    uint16 _currentChainId
  ) {
    __initStewarded(_steward);
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
  // (senderId => receiverId => (uint64 nonce, bytes payload)[])
  mapping(uint256 => mapping(uint256 => bytes[])) public receivedMessage;

  function readMessage(uint256 senderId, uint256 receiverId)
    public
    view
    returns (bytes memory)
  {
    bytes[] memory messages = receivedMessage[senderId][receiverId];
    (, bytes memory payload) = abi.decode(
      messages[messages.length - 1],
      (uint64, bytes)
    );
    return payload;
  }

  function readMessage(
    uint256 senderId,
    uint256 receiverId,
    uint64 withNonce
  ) public view returns (bytes memory) {
    bytes[] memory messages = receivedMessage[senderId][receiverId];
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

  function receivedMessageCount(uint256 senderId, uint256 receiverId)
    public
    view
    returns (uint256)
  {
    return receivedMessage[senderId][receiverId].length;
  }

  function receiveMessage(
    uint16, // fromChainId
    bytes calldata, // fromContractAddress,
    uint64 msgNonce,
    bytes calldata payload
  ) internal override {
    (uint256 senderId, uint256 receiverId, bytes memory data) = abi.decode(
      payload,
      (uint256, uint256, bytes)
    );

    receivedMessage[senderId][receiverId].push(abi.encode(msgNonce, data));
    emit Message(currentChainId, msgNonce, senderId, receiverId, data);
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
    uint256 withSenderId,
    uint256 toReceiverId
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
    uint256 withSenderId,
    uint16 onChainId,
    uint256 toReceiverId,
    bytes memory data,
    address lzPaymentAddress,
    bytes calldata lzAdapterParams
  ) public payable {
    require(
      canWriteMessage(msg.sender, withSenderId, toReceiverId),
      "Omnicast: UNAUTHORIZED"
    );

    if (onChainId == currentChainId) {
      uint64 msgNonce = nonce++;
      receivedMessage[withSenderId][toReceiverId].push(
        abi.encode(msgNonce, data)
      );

      emit Message(onChainId, msgNonce, withSenderId, toReceiverId, data);
    } else {
      lzSend(
        onChainId,
        abi.encode(withSenderId, toReceiverId, data),
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
