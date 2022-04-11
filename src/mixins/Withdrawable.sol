// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Auth} from "@rari-capital/solmate/auth/Auth.sol";

interface TransferrableToken {
  function transferFrom(
    address from,
    address to,
    uint256 idOrAmount
  ) external;
}

abstract contract Withdrawable is Auth {
  function withdrawTo(address to, uint256 amount) public requiresAuth {
    payable(to).transfer(amount);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 idOrAmount
  ) public requiresAuth {
    TransferrableToken(token).transferFrom(address(this), to, idOrAmount);
  }
}
