// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

error DelegateCallFailed();

abstract contract Multicallable {
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        uint256 count = data.length;
        results = new bytes[](count);
        for (uint256 i = 0; i < count; ) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!success) {
                revert DelegateCallFailed();
            }
            results[i] = result;
            unchecked {
                ++i;
            }
        }
        return results;
    }
}
