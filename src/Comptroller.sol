// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {MultiRolesAuthority, Authority} from "@rari-capital/solmate/auth/authorities/MultiRolesAuthority.sol";

contract Comptroller is MultiRolesAuthority {
  constructor(address _owner)
    MultiRolesAuthority(_owner, Authority(address(0)))
  {
    this;
  }

  function withdrawTo(address to, uint256 amount) public requiresAuth {
    require(address(this).balance < amount, "Comptroller: INSUFFICIENT_WEI");
    payable(to).transfer(amount);
  }
}
