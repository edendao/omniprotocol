// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

abstract contract ReentrancyGuard {
  uint256 private locked;

  function __initReentrancyGuard() internal {
    locked = 1;
  }

  modifier nonReentrant() {
    require(locked == 1, "REENTRANCY");

    locked = 2;

    _;

    locked = 1;
  }
}
