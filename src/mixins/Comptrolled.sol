// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";
import {Auth, Authority} from "@protocol/auth/Auth.sol";
import {Comptroller} from "@protocol/Comptroller.sol";

abstract contract Comptrolled is Auth {
  function __initComptrolled(address _comptroller) internal {
    __initAuth(Auth(_comptroller).owner(), Authority(_comptroller));
  }

  function withdraw(uint256 amount) external requiresAuth {
    payable(address(authority)).transfer(amount);
  }

  function withdrawToken(address token, uint256 amount)
    external
    virtual
    requiresAuth
  {
    TransferToken(token).transfer(address(authority), amount);
  }
}
