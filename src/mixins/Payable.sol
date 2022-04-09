// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@rari-capital/solmate/tokens/ERC20.sol";

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";

contract Payable is Comptrolled {
  constructor(address _comptroller) Comptrolled(_comptroller) {
    this;
  }

  function withdrawTo(address to, uint256 amount) public requiresAuth {
    payable(to).transfer(amount);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) public requiresAuth returns (bool) {
    return ERC20(token).transfer(to, amount);
  }
}
