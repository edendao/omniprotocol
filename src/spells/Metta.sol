// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { Spell } from "@protocol/mixins/Spell.sol";

contract Metta is Spell {
  constructor(address _authority, address _note) Spell(_authority, _note) {
    this;
  }

  function cast() external payable returns (uint256) {
    return earnXP(msg.sender, msg.value);
  }

  receive() external payable {
    earnXP(msg.sender, msg.value);
  }
}
