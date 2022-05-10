// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

interface IOmnicast {
  // Use nonce to correlate messages across chains from the frontend
  event Message(
    uint16 indexed chainId,
    uint64 nonce,
    uint256 indexed receiverId,
    uint256 indexed senderId,
    bytes data
  );

  // Emits `Message` w/ a nonce
  // Mainnet Chain IDs
  // https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
  // Testnets Chain IDs
  // https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses
  function writeMessage(
    uint256 toReceiverId, // use idOf(address account)
    uint256 withSenderId, // use idOf(address account) or idOf(omnicast name)
    bytes memory payload, // abi.encode anything you please!
    uint16 onChainId,
    address lzPaymentAddress,
    bytes memory lzAdapterParams
  ) external payable;

  // Read the latest message
  function readMessage(uint256 receiverId, uint256 senderId)
    external
    view
    returns (bytes memory data);

  // Read the latest message
  function readMessage(
    uint256 receiverId,
    uint256 senderId,
    uint64 withNonce
  ) external view returns (bytes memory data);

  // Load a message at a specific index
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
