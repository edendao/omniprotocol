// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Factory} from "@protocol/mixins/Factory.sol";

import {Comptroller} from "@protocol/auth/Comptroller.sol";

contract ComptrollerFactory is Factory, Comptrolled {
  constructor(address _comptroller)
    Comptrolled(_comptroller)
    Factory(type(Comptroller).creationCode)
  {
    this;
  }

  function create() public payable returns (address) {
    return _create(abi.encode(msg.sender));
  }

  function create(address owner) public payable returns (address) {
    return _create(abi.encode(owner));
  }
}
