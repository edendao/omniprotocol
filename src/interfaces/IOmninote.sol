// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOmninote {
  function mintTo(address to, uint256 x) external returns (uint256);

  function burnFrom(address from, uint256 x) external returns (uint256);

  function remoteNote(uint16 onChainId) external view returns (bytes memory);
}
