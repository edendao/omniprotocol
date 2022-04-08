// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

error Immovable();

abstract contract Soulbound {
  function transferFrom(
    address, // from
    address, // to
    uint256 // id
  ) external payable {
    revert Immovable();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256 // id
  ) external payable {
    revert Immovable();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256, // id,
    bytes calldata // payload
  ) external payable {
    revert Immovable();
  }
}
