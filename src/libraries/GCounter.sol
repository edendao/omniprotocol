// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

error MismatchedArrayLengths();

library GCounter {
    function increment(
        uint256[] storage counters,
        uint256 slot,
        uint256 amount
    ) internal {
        counters[slot] += amount;
    }

    function value(uint256[] memory counters)
        internal
        pure
        returns (uint256 sum)
    {
        for (uint256 i = 0; i < counters.length; ) {
            sum += counters[i];
            unchecked {
                ++i;
            }
        }
    }

    function merge(
        uint256[] storage counters,
        uint256[] memory receivedCounters
    ) internal {
        if (counters.length != receivedCounters.length) {
            revert MismatchedArrayLengths();
        }
        for (uint256 i = 0; i < counters.length; ) {
            uint256 receivedCounter = receivedCounters[i];
            if (counters[i] < receivedCounter) {
                counters[i] = receivedCounter;
            }
            unchecked {
                ++i;
            }
        }
    }
}
