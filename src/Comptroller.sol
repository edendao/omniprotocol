// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {MultiRolesAuthority, Authority} from "@rari-capital/solmate/auth/authorities/MultiRolesAuthority.sol";

interface TransferrableToken {
  function transfer(address to, uint256 idOrAmount) external;
}

contract Comptroller is MultiRolesAuthority {
  constructor(address _owner)
    MultiRolesAuthority(_owner, Authority(address(0)))
  {
    this;
  }

  function withdrawTo(address to, uint256 amount) public requiresAuth {
    payable(to).transfer(amount);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) public requiresAuth {
    TransferrableToken(token).transfer(to, amount);
  }
}
