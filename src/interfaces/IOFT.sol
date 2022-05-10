// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

// For compatibility with LayerZero's OFT standard
interface IOFT {
  function sendFrom(
    address from,
    uint16 toChainId,
    bytes memory toAddress,
    uint256 amount,
    address payable refundAddress,
    address zroPaymentAddress,
    bytes memory adapterParams
  ) external payable;

  function estimateSendFee(
    uint16 toChainId,
    bytes memory toAddress,
    uint256 amount,
    bool useZRO,
    bytes memory adapterParams
  ) external view returns (uint256 nativeFee, uint256 zroFee);

  function circulatingSupply() external view returns (uint256);

  event SendToChain(
    address indexed fromAddress,
    uint16 indexed toChainId,
    bytes indexed toAddress,
    uint256 amount,
    uint64 nonce
  );

  event ReceiveFromChain(
    uint16 indexed fromChainId,
    bytes indexed fromContractAddress,
    address indexed toAddress,
    uint256 amount,
    uint64 nonce
  );
}
