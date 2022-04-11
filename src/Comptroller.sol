// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Withdrawable} from "@protocol/mixins/Withdrawable.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {MultiRolesAuthority, Authority} from "@rari-capital/solmate/auth/authorities/MultiRolesAuthority.sol";

contract Comptroller is MultiRolesAuthority, Withdrawable {
  constructor(address _owner)
    MultiRolesAuthority(_owner, Authority(address(0)))
  {
    this;
  }

  function layerZeroTransactionParams() public pure returns (bytes memory) {
    return "";
  }
}
