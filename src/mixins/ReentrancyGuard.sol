// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

abstract contract ReentrancyGuard {
    bool private _reentrancyGuard;

    modifier nonReentrant() {
        require(!_reentrancyGuard, "REENTRANT");
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }
}
