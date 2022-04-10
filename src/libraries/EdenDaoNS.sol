// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library EdenDaoNS {
  function namehash(string memory node) public pure returns (uint256) {
    return
      uint256(keccak256(bytes(node))) +
      uint256(
        0x5ca3623722713eca5a0b5378cb4acc8f1fa542099cd3f4d8a29ab109339366e0
      );
  }
}
