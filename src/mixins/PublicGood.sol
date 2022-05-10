// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

abstract contract PublicGood is Comptrolled {
  uint16 public constant MAX_BPS = 10_000;
  uint16 public goodPoints = 25; // 0.25% for the planet
  address public beneficiary;

  event SetBeneficiary(address beneficiary);

  function __initPublicGood(address _beneficiary) internal {
    beneficiary = _beneficiary;
    emit SetBeneficiary(_beneficiary);
  }

  event SetGoodPoints(uint16 points);

  function setGoodPoints(uint16 _points) external requiresAuth {
    require(10 <= _points && _points <= MAX_BPS, "PublicGood: INVALID_BP");
    goodPoints = _points;
    emit SetGoodPoints(_points);
  }

  bool internal isInitialized;

  modifier initializer() {
    require(!isInitialized, "ALREADY_INITIALIZED");
    _;
    isInitialized = true;
  }

  function initialize(address, bytes calldata) external virtual {
    revert("UNIMPLEMENTED");
  }

  event CreateClone(address indexed implementation);

  function clone(bytes memory params)
    public
    payable
    returns (address cloneAddress)
  {
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
      cloneAddress := create(0, code, 0x37)
    }

    PublicGood(cloneAddress).initialize(beneficiary, params);
    emit CreateClone(cloneAddress);
  }
}
