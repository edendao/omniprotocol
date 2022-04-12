// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOmnicast {
  function readMessage(uint256 omniReceiverId, uint256 omniSenderId)
    external
    view
    returns (bytes memory);

  function sendMessage(
    uint16 toChainId,
    uint256 toReceiverId,
    uint256 withCasterId,
    bytes memory payload,
    address lzPaymentAddress,
    bytes memory lzTransactionParams
  ) external payable;
}
