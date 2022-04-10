// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Auth, Authority} from "@rari-capital/solmate/auth/Auth.sol";

interface TransferrableToken {
  function transfer(address to, uint256 idOrAmount) external;
}

contract Comptrolled is Auth {
  constructor(address _authority)
    Auth(Auth(_authority).owner(), Authority(_authority))
  {
    this;
  }

  function comptroller() public view returns (Authority) {
    return authority;
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
