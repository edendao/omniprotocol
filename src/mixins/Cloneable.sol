// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {Initializable} from "@protocol/mixins/Initializable.sol";

abstract contract Cloneable is Initializable {
  uint256 private _cloneId;

  event CreateClone(address indexed implementation);

  function clone() internal returns (address cloneAddress) {
    return clone(keccak256(abi.encode(_cloneId++)));
  }

  function clone(bytes32 salt) internal returns (address cloneAddress) {
    bytes20 targetBytes = bytes20(address(this));
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let code := mload(0x40)
      mstore(
        code,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(code, 0x14), targetBytes)
      mstore(
        add(code, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      cloneAddress := create2(0, code, 0x37, salt)
    }
    emit CreateClone(cloneAddress);
  }
}
