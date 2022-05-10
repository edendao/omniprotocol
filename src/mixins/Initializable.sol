// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

abstract contract Initializable {
  bool internal isInitialized;

  function initialize(address, bytes calldata) external virtual;

  modifier initializer() {
    require(!isInitialized, "ALREADY_INITIALIZED");
    _;
    isInitialized = true;
  }
}
