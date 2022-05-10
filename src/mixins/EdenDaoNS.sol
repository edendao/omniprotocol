// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

contract EdenDaoNS {
  // cast namehash eden.dao
  bytes32 internal constant domain =
    0x5ca3623722713eca5a0b5378cb4acc8f1fa542099cd3f4d8a29ab109339366e0;

  function namehash(string memory subdomain) public pure returns (uint256) {
    return (
      uint256(
        keccak256(
          abi.encodePacked(domain, keccak256(abi.encodePacked(subdomain)))
        )
      )
    );
  }

  function idOf(address account) public pure returns (uint256 id) {
    id = uint256(uint160(account));
  }

  function idOf(string memory name) public pure returns (uint256 id) {
    id = namehash(name);
    require(id > type(uint160).max, "RESERVED_SPACE");
  }
}
