// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC721, IERC721Metadata} from "@boring/interfaces/IERC721.sol";

error Soulbound();

abstract contract ERC721Soulbound is IERC721 {
  function approve(address, uint256) external payable {
    revert Soulbound();
  }

  function setApprovalForAll(address, bool) external pure {
    revert Soulbound();
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
    revert Soulbound();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256 // id
  ) public payable virtual {
    revert Soulbound();
  }

  function safeTransferFrom(
    address, // from
    address, // to
    uint256, // id,
    bytes calldata // payload
  ) public payable virtual {
    revert Soulbound();
  }
}
