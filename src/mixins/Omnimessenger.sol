// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

import {Omnichannel} from "@protocol/Omnichannel.sol";

contract Omnimessenger is Omnichain, Pausable {
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

  // (myOmnimessengerId => onOmnichannelId => data)
  mapping(uint256 => mapping(uint256 => bytes)) public readMessage;

  // Base utility — read and write cross-chain identified by the address of the writer
  function sendMessage(
    uint16 toChainId,
    address toAddress,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public payable {
    sendMessage(
      toChainId,
      uint256(uint160(toAddress)),
      idOf(msg.sender),
      payload,
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  function readMessageFor(address omnicastId, address onOmnichannelId)
    public
    view
    returns (bytes memory)
  {
    return readMessage[idOf(omnicastId)][idOf(onOmnichannelId)];
  }

  // Omnichannel — specify the address and branded omnichannel name to write to
  function sendMessage(
    uint16 toChainId,
    address toAddress,
    string memory omnichannelName,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public payable {
    sendMessage(
      toChainId,
      uint256(uint160(toAddress)),
      omnichannel.idOf(omnichannelName),
      payload,
      lzPaymentAddress,
      lzTransactionParams
    );
  }

  function readMessageFor(address omnicastId, string memory channelName)
    public
    view
    returns (bytes memory)
  {
    return readMessage[idOf(omnicastId)][omnichannel.idOf(channelName)];
  }

  // Maximum control — specify the omnicast and omnichannel by ID
  function sendMessage(
    uint16 toChainId,
    uint256 toOmnireceiverId,
    uint256 onOmnichannelId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) public payable whenNotPaused {
    require(
      (msg.sender == address(uint160(toOmnireceiverId)) ||
        onOmnichannelId == idOf(msg.sender) ||
        msg.sender == omnichannel.ownerOf(onOmnichannelId)),
      "Omnimessenger: UNAUTHORIZED_CHANNEL"
    );

    if (toChainId == currentChainId) {
      readMessage[toOmnireceiverId][onOmnichannelId] = payload;
    } else {
      lzSend(
        toChainId,
        abi.encode(toOmnireceiverId, onOmnichannelId, payload),
        lzPaymentAddress,
        lzTransactionParams
      );
    }

    emit Message(toChainId, toOmnireceiverId, onOmnichannelId, payload);
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
}
