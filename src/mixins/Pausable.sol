// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@rari-capital/solmate/auth/Auth.sol";

abstract contract Pausable is Auth {
  bool public isPaused;

  function pause() external requiresAuth {
    isPaused = true;
  }

  function resume() external requiresAuth {
    isPaused = false;
  }
}
