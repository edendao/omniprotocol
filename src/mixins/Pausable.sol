// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {Auth} from "./auth/Auth.sol";

error Paused();

abstract contract Pausable is Auth {
    bool public isPaused;

    modifier whenNotPaused() {
        if (isPaused) {
            revert Paused();
        }
        _;
    }

    function pause() external requiresAuth {
        isPaused = true;
    }

    function resume() external requiresAuth {
        isPaused = false;
    }
}
