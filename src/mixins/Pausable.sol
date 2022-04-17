// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract Pausable is Comptrolled {
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
