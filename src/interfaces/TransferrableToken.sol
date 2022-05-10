// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

interface TransferFromToken {
  function transferFrom(
    address from,
    address to,
    uint256 idOrAmount
  ) external;
}

interface TransferToken {
  function transfer(address to, uint256 idOrAmount) external;
}
