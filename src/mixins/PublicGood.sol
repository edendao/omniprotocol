// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract PublicGood is Comptrolled {
  uint16 public constant MAX_BPS = 10_000;
  uint16 public goodPoints = 100; // 1% for the planet
  address public beneficiary;

  function __initPublicGood(address _beneficiary) internal {
    beneficiary = _beneficiary;
  }

  event GoodPointsUpdated(address indexed user, uint16 points);

  function setGoodPoints(uint16 points) public requiresAuth {
    require(10 <= points && points <= MAX_BPS, "PublicGood: INVALID_BP");
    goodPoints = points;
    emit GoodPointsUpdated(msg.sender, points);
  }
}
