// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";
import {Auth} from "@protocol/auth/Auth.sol";
import {Comptroller} from "@protocol/Comptroller.sol";

abstract contract Comptrolled is Auth {
  function __initComptrolled(address _comptroller) internal {
    Comptroller comptroller = Comptroller(payable(_comptroller));
    __initAuth(comptroller.owner(), comptroller);
  }

  function comptrollerAddress() public view returns (address) {
    return address(authority);
  }

  function withdraw(uint256 amount) external requiresAuth {
    payable(comptrollerAddress()).transfer(amount);
  }

  function withdrawToken(address token, uint256 amount)
    external
    virtual
    requiresAuth
  {
    TransferToken(token).transfer(comptrollerAddress(), amount);
  }
}
