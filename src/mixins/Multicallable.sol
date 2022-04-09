// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract Multicallable {
  function multicall(bytes[] calldata data)
    external
    returns (bytes[] memory results)
  {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);
      require(success, "Multicallable: DELEGATE_CALL_FAILED");
      results[i] = result;
    }
    return results;
  }
}
