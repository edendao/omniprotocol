// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC4626} from "@protocol/mixins/ERC4626.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";
import {Cloneable} from "@protocol/mixins/Cloneable.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Omnitoken} from "@protocol/Omnitoken.sol";

contract Omnibridge is PublicGood {
  address public immutable omnitoken;

  constructor(address _comptroller, address _omnitoken) {
    __initPublicGood(_comptroller);
    __initComptrolled(_comptroller);

    omnitoken = _omnitoken;
  }

  event CreateComptroller(address indexed owner, address comptroller);

  function createComptroller(address _owner) external returns (Comptroller c) {
    c = Comptroller(
      payable(createClone(comptrollerAddress(), abi.encode(_owner)))
    );
    emit CreateComptroller(_owner, address(c));
  }

  event CreateOmnitoken(
    address indexed comptroller,
    string name,
    string symbol,
    uint8 decimals
  );

  function createOmnitoken(
    address _comptroller,
    address _lzEndpoint,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) external returns (Omnitoken n) {
    n = Omnitoken(
      createClone(
        omnitoken,
        abi.encode(_comptroller, _lzEndpoint, _name, _symbol, _decimals)
      )
    );
    emit CreateOmnitoken(_comptroller, _name, _symbol, _decimals);
  }

  function createClone(address target, bytes memory params)
    internal
    returns (address deployedAddress)
  {
    bytes20 targetBytes = bytes20(target);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let clone := mload(0x40)
      mstore(
        clone,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(clone, 0x14), targetBytes)
      mstore(
        add(clone, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      deployedAddress := create(0, clone, 0x37)
    }
    Cloneable(deployedAddress).initialize(comptrollerAddress(), params);
  }
}
