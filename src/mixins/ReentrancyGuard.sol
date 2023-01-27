// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

error Reentrant();

abstract contract ReentrancyGuard {
    bool private _reentrancyGuard;

    modifier nonReentrant() {
        if (_reentrancyGuard) {
            revert Reentrant();
        }
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }
}
