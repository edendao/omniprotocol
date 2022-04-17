// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

error Immovable();

abstract contract ERC721Soulbound is IERC721 {
  function approve(address, uint256) external payable {
    revert Immovable();
  }

  function setApprovalForAll(address, bool) external pure {
    revert Immovable();
  }

  function getApproved(uint256) external pure returns (address) {
    return address(0);
  }

  function isApprovedForAll(address, address) external pure returns (bool) {
    return false;
  }

  function transferFrom(
    address, // from
    address, // to
    uint256 // id
  ) public payable virtual {
    revert Immovable();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256 // id
  ) public payable virtual {
    revert Immovable();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256, // id,
    bytes calldata // payload
  ) public payable virtual {
    revert Immovable();
  }
}
