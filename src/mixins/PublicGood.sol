// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

abstract contract PublicGood {
  bool internal isInitialized;
  address public beneficiary;

  function initialize(address _beneficiary, bytes memory _params) public {
    require(!isInitialized, "ALREADY_INITIALIZED");
    beneficiary = _beneficiary;
    _initialize(_params);
    isInitialized = true;
  }

  function _initialize(bytes memory _params) internal virtual;

  modifier onlyBeneficiary() {
    require(msg.sender == beneficiary, "UNAUTHORIZED");
    _;
  }
}
