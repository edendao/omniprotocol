// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

library GCounter {
  function incrementBy(
    uint256[] storage counters,
    uint256 slot,
    uint256 amount
  ) internal {
    counters[slot] += amount;
  }

  function value(uint256[] memory counters) internal pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < counters.length; i++) {
      sum += counters[i];
    }
    return sum;
  }

  function merge(uint256[] storage counters, uint256[] memory receivedCounters)
    internal
  {
    require(
      counters.length == receivedCounters.length,
      "GCounter: Cannot merge unrelated counters"
    );
    for (uint256 i = 0; i < counters.length; i++) {
      if (counters[i] < receivedCounters[i]) {
        counters[i] = receivedCounters[i];
      }
    }
  }
}
