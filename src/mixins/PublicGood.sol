// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract PublicGood is Comptrolled {
  uint16 public constant MAX_BPS = 10_000;
  uint16 public goodPoints = 100; // 1% for the planet
  address public immutable beneficiary;

  constructor(address _beneficiary) {
    beneficiary = _beneficiary;
  }

  event GoodPointsUpdated(address indexed user, uint256 newgoodPoints);

  function setGoodPoints(uint16 points) public requiresAuth {
    require(10 <= points, "PublicGood: INVALID_BP"); // 0.1% or more
    goodPoints = points;
    emit GoodPointsUpdated(msg.sender, points);
  }

  // From Solmate
  function _mulDivDown(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 z) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Store x * y in z for now.
      z := mul(x, y)

      // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
      if iszero(
        and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))
      ) {
        revert(0, 0)
      }

      // Divide z by the denominator.
      z := div(z, denominator)
    }
  }
}
