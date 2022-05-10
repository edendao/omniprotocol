// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {Auth} from "@protocol/auth/Auth.sol";

abstract contract Pausable is Auth {
  bool public isPaused;

  modifier whenNotPaused() {
    require(!isPaused, "Pausable: PAUSED");
    _;
  }

  function pause() external requiresAuth {
    isPaused = true;
  }

  function resume() external requiresAuth {
    isPaused = false;
  }
}
