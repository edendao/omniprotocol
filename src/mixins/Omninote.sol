// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmninote} from "@protocol/interfaces/IOmninote.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract Omninote is IOmninote, Comptrolled {
  function mint(address to, uint256 id) public virtual returns (uint256);

  function burn(address, uint256 id) public virtual returns (uint256);

  mapping(uint16 => bytes) public remoteNote;

  function setRemoteNote(uint16 onChainId, bytes memory remoteNoteAddressB)
    external
    requiresAuth
  {
    remoteNote[onChainId] = remoteNoteAddressB;
  }
}
