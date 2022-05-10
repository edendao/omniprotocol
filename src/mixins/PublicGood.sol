// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

abstract contract PublicGood {
  address public beneficiary;

  event SetBeneficiary(address beneficiary);

  function __initPublicGood(address _beneficiary) internal {
    beneficiary = _beneficiary;
    emit SetBeneficiary(_beneficiary);
  }
}
