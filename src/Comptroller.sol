// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { MultiRolesAuthority, Authority } from "@rari-capital/solmate/auth/authorities/MultiRolesAuthority.sol";

contract Comptroller is MultiRolesAuthority {
  constructor(address _owner)
    MultiRolesAuthority(_owner, Authority(address(0)))
  {
    this;
  }
}
