// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { OmniNFT, Omnichain, Authenticated } from "@protocol/mixins/OmniNFT.sol";

/*
 * The Passport is your cross-chain identity for the omnichain future.
 */
contract Passport is OmniNFT {
  constructor(address _authority, address _lzEndpoint)
    OmniNFT(_authority, _lzEndpoint, "Eden Dao Passport", "PASSPORT")
  {
    this;
  }
}
