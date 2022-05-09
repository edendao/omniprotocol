// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IOmnibridge {
  function sendFrom(
    address omnitokenAddress,
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    address lzPaymentAddress,
    bytes calldata lzAdapterParams
  ) external payable;

  function estimateSendFee(
    uint16 toChainId,
    bool useZRO,
    bytes calldata lzAdapterParams
  ) external view returns (uint256 gasFees, uint256 lzFees);
}
