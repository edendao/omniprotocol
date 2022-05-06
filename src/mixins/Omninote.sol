// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IOmninote} from "@protocol/interfaces/IOmninote.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract Omninote is IOmninote, Comptrolled {
  mapping(uint16 => bytes) public remoteContract;

  function setRemoteContract(
    uint16 onChainId,
    bytes memory remoteContractAddressB
  ) external requiresAuth {
    remoteContract[onChainId] = remoteContractAddressB;
  }
}
