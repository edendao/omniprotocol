// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {DSTestPlus} from "@solmate/test/utils/DSTestPlus.sol";

import {GCounter} from "@protocol/libraries/GCounter.sol";

contract GCounterTest is DSTestPlus {
  using GCounter for uint256[];

  uint256[] internal slots = [256, 12, 128, 0, 0];

  function testValue() public {
    uint256 value = slots.value();
    assertEq(value, 396);
  }

  function testIncrementBy() public {
    uint256 _amount = 256;
    uint256 value = slots.value();
    slots.incrementBy(1, _amount);
    assertEq(slots.value(), value + _amount);
  }

  function testMerge() public {
    uint256 _delta = 172;
    uint256 value = slots.value();
    uint256[] memory payload = new uint256[](5);
    payload[4] = _delta;
    slots.merge(payload);
    assertEq(slots.value(), value + _delta);
  }
}
