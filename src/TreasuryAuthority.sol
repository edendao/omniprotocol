// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { MultiRolesAuthority, Authority } from "@rari-capital/solmate/auth/authorities/MultiRolesAuthority.sol";

contract TreasuryAuthority is MultiRolesAuthority {
  constructor(address _owner, address _authority)
    MultiRolesAuthority(_owner, Authority(_authority))
  {
    this;
  }
}
