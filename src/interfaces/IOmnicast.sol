// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IOmnicast {
  function idOf(address to) external returns (uint256);

  function readMessage(uint256 omniReceiverId, uint256 omniSenderId)
    external
    view
    returns (bytes memory);

  function readMessageFor(address omniReceiverId, address omniSenderId)
    external
    view
    returns (bytes memory);

  function readMessageFor(address omniReceiverId, string memory channelName)
    external
    view
    returns (bytes memory);

  // Base utility — read and write cross-chain identified by the address of the writer
  function sendMessage(
    uint16 toChainId,
    address toAddress,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable;

  // Omnichannel — specify the address and branded omnichannel name to write to
  function sendMessage(
    uint16 toChainId,
    address toAddress,
    string memory omnichannelName,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable;

  // Maximum control — specify the omnicast and omnichannel by ID
  function sendMessage(
    uint16 toChainId,
    uint256 toOmnireceiverId,
    uint256 onOmnichannelId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable;
}
