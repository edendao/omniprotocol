// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOmnicaster {
  function idOf(address account) external view returns (uint256 omnicastId);

  function idOf(string memory name) external view returns (uint256 omnicastId);

  function sendMessage(
    uint16 toChainId,
    uint256 toReceiverId,
    uint256 withSenderId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable;

  function readMessage(uint256 receiverId, uint256 senderId)
    external
    view
    returns (bytes memory data);

  function receivedMessages(
    uint256 receiverId,
    uint256 senderId,
    uint256 messageIndex
  ) external view returns (bytes memory data);

  function receivedMessagesCount(uint256 receiverId, uint256 senderId)
    external
    view
    returns (uint256 messagesCount);
}
