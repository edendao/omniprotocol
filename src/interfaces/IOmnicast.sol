// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

interface IOmnicast {
  // id for a given account address, can be used for senderId and receiverId
  function idOf(address account) external pure returns (uint256 id);

  // id for a given subdomain of eden.dao, can be used for senderId and receiverId
  function idOf(string memory name) external pure returns (uint256 id);

  // Use nonce to correlate messages across chains from the frontend
  event Message(
    uint16 indexed chainId,
    uint64 nonce,
    uint256 indexed senderId,
    uint256 indexed receiverId,
    bytes data
  );

  // Emits `Message` w/ a nonce
  // Mainnet Chain IDs
  // https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
  // Testnets Chain IDs
  // https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses
  function writeMessage(
    uint256 withSenderId, // use idOf(address account) or idOf(omnicast name)
    uint16 onChainId,
    uint256 toReceiverId, // use idOf(address account)
    bytes memory payload, // abi.encode anything you please!
    address lzPaymentAddress,
    bytes memory lzAdapterParams
  ) external payable;

  // Read the latest message
  function readMessage(uint256 senderId, uint256 receiverId)
    external
    view
    returns (bytes memory data);

  // Lookup by a nonce
  function readMessage(
    uint256 senderId,
    uint256 receiverId,
    uint64 withNonce
  ) external view returns (bytes memory data);

  // Lookup by index
  function receivedMessage(
    uint256 senderId,
    uint256 receiverId,
    uint256 messageIndex
  ) external view returns (bytes memory data);

  // Get count
  function receivedMessageCount(uint256 senderId, uint256 receiverId)
    external
    view
    returns (uint256 messagesCount);
}
