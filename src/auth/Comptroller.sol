// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {MultiRolesAuthority, Authority} from "@rari-capital/solmate/auth/authorities/MultiRolesAuthority.sol";

import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";

import {Multicallable} from "@protocol/mixins/Multicallable.sol";

contract Comptroller is MultiRolesAuthority, Multicallable {
  constructor(address _owner)
    MultiRolesAuthority(_owner, Authority(address(0)))
  {
    setAuthority(this);
  }

  function withdrawTo(address to, uint256 amount) external requiresAuth {
    payable(to).transfer(amount);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) external requiresAuth {
    TransferToken(token).transfer(to, amount);
  }

  receive() external payable {
    this;
  }
}
