// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { Auth, Authority } from "@rari-capital/solmate/auth/Auth.sol";

contract Authenticated is Auth {
  constructor(address _authority)
    Auth(Auth(_authority).owner(), Authority(_authority))
  {
    this;
  }
}
