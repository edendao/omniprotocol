// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

error Reentrant();

abstract contract ReentrancyGuard {
    bool private _inCall;

    modifier nonReentrant() {
        if (_inCall) {
            revert Reentrant();
        }
        _inCall = true;
        _;
        _inCall = false;
    }
}
