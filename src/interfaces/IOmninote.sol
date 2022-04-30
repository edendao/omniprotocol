// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOmninote {
  function mint(address receiver, uint256 amount) external returns (uint256);

  function burn(address owner, uint256 amount) external returns (uint256);

  function remoteNote(uint16 onChainId) external view returns (bytes memory);
}
