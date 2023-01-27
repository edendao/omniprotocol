// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

error AlreadyInitialized();
error Unauthorized();

abstract contract PublicGood {
    bool internal initialized;
    address public beneficiary;

    function initialize(address _beneficiary, bytes memory _params) public {
        if (initialized) {
            revert AlreadyInitialized();
        }

        beneficiary = _beneficiary;
        _initialize(_params);

        initialized = true;
    }

    function _initialize(bytes memory _params) internal virtual;

    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary) {
            revert Unauthorized();
        }

        _;
    }
}
