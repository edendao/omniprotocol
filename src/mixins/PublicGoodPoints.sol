// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {Auth} from "@protocol/auth/Auth.sol";

abstract contract GoodPoints is Auth {
  // ================================
  // ========= Public Good ==========
  // ================================
  uint16 public constant MAX_BPS = 10_000;
  uint16 public goodPoints = 25; // 0.25% for the planet

  event SetGoodPoints(uint16 points);

  function setGoodPoints(uint16 basisPoints) external requiresAuth {
    require(
      10 <= basisPoints && basisPoints <= MAX_BPS,
      "PublicGood: INVALID_BP"
    );
    goodPoints = basisPoints;
    emit SetGoodPoints(basisPoints);
  }
}
