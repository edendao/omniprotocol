// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Auth, Authority} from "@rari-capital/solmate/auth/Auth.sol";

import {Withdrawable} from "@protocol/mixins/Withdrawable.sol";
import {Comptroller} from "@protocol/Comptroller.sol";

contract Comptrolled is Withdrawable {
  constructor(address _authority)
    Auth(Auth(_authority).owner(), Authority(_authority))
  {
    this;
  }

  function comptroller() public view returns (Comptroller) {
    return Comptroller(comptrollerAddress());
  }

  function comptrollerAddress() public view returns (address) {
    return address(authority);
  }
}
