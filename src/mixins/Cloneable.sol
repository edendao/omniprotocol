// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

contract Cloneable {
  bool internal isInitialized;

  modifier initializer() {
    require(!isInitialized, "Cloneable: INVARIANT");
    _;
    isInitialized = true;
  }

  function initialize(address, bytes calldata) external virtual {
    revert("Cloneable: NOT_IMPLEMENTED");
  }
}
