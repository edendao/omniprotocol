// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IOmnibridge {
  function sendNote(
    address noteAddress,
    uint256 amount,
    uint16 toChainId,
    bytes calldata toAddress,
    address lzPaymentAddress,
    bytes calldata lzTransactionParams
  ) external payable;

  // Receive notes from omnispace
  event ReceiveNote(
    uint16 indexed fromChainId,
    uint64 nonce,
    address indexed noteAddress,
    address indexed toAddress,
    uint256 amount
  );

  function estimateLayerZeroGas(
    uint16 toChainId,
    bool useZRO,
    bytes calldata lzTransactionParams
  ) external view returns (uint256 gasFees, uint256 lzFees);
}
