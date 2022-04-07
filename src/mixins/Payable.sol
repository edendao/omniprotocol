// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { ERC20 } from "@rari-capital/solmate/tokens/ERC20.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";

contract Payable is Authenticated {
  constructor(address _authority) Authenticated(_authority) {
    this;
  }

  function withdraw(address to, uint256 amount) public requiresAuth {
    payable(to).transfer(amount);
  }

  function withdrawToken(
    address to,
    address token,
    uint256 amount
  ) public requiresAuth returns (bool) {
    return ERC20(token).transfer(to, amount);
  }
}
