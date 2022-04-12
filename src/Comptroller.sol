// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {MultiRolesAuthority, Authority} from "@rari-capital/solmate/auth/authorities/MultiRolesAuthority.sol";

import {TransferFromToken} from "@protocol/interfaces/TransferFromToken.sol";

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
    uint256 idOrAmount
  ) public requiresAuth {
    TransferFromToken(token).transferFrom(address(this), to, idOrAmount);
  }
}
