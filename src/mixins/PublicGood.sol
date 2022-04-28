// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract PublicGood is Comptrolled {
  address public immutable beneficiary;
  uint256 public goodPercent = 1e16; // 1% for the planet

  constructor(address _beneficiary) {
    beneficiary = _beneficiary;
  }

  event DidGood(
    address indexed user,
    uint256 indexed flowAmount,
    uint256 goodAmount
  );

  event GoodPercentUpdated(address indexed user, uint256 newgoodPercent);

  function setGoodPercent(uint256 newGoodPercent) public requiresAuth {
    require(1e15 <= newGoodPercent, "PublicGood: TOO_LOW"); // 0.1% or more
    goodPercent = newGoodPercent;
    emit GoodPercentUpdated(msg.sender, newGoodPercent);
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
