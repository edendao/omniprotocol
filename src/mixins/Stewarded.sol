// SPDX-License-Identifier: AGLP-3.0-only
pragma solidity ^0.8.13;

import {TransferToken} from "@omniprotocol/interfaces/TransferrableToken.sol";
import {Auth, Authority} from "@omniprotocol/auth/Auth.sol";
import {Steward} from "@omniprotocol/Steward.sol";

abstract contract Stewarded is Auth {
  function __initStewarded(address _steward) internal {
    __initAuth(Auth(_steward).owner(), Authority(_steward));
  }

  function withdraw(uint256 amount) public requiresAuth {
    payable(address(authority)).transfer(amount);
  }

  function withdrawToken(address token, uint256 amount)
    public
    virtual
    requiresAuth
  {
    TransferToken(token).transfer(address(authority), amount);
  }
}
