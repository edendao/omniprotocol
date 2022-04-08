// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "@rari-capital/solmate/auth/Auth.sol";

abstract contract Pausable is Auth {
  bool public isPaused;

  modifier whenNotPaused() {
    require(!isPaused, "Pausable: Paused");
    _;
  }

  function pause() external requiresAuth {
    isPaused = true;
  }

  function resume() external requiresAuth {
    isPaused = false;
  }
}
