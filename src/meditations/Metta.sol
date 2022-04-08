// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { Meditation } from "@protocol/mixins/Meditation.sol";

contract Metta is Meditation {
  constructor(address _authority, address _note) Meditation(_authority, _note) {
    this;
  }

  function perform() external payable returns (uint256) {
    return earnXP(msg.sender, msg.value);
  }

  receive() external payable {
    earnXP(msg.sender, msg.value);
  }
}
