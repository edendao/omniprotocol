// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";

import {Comptroller} from "@protocol/auth/Comptroller.sol";

abstract contract Comptrolled {
  Comptroller public comptroller;

  constructor(address _comptroller) {
    comptroller = Comptroller(payable(_comptroller));
  }

  modifier requiresAuth() {
    require(isAuthorized(msg.sender, msg.sig), "Comptrolled: UNAUTHORIZED");
    _;
  }

  // Delegate to Comptroller
  function isAuthorized(address user, bytes4 functionSig)
    public
    view
    returns (bool)
  {
    return (comptroller.canCall(user, address(this), functionSig) ||
      user == comptroller.owner());
  }

  function comptrollerAddress() public view returns (address) {
    return address(comptroller);
  }

  function withdraw(uint256 amount) public requiresAuth {
    payable(comptrollerAddress()).transfer(amount);
  }

  function withdrawToken(address token, uint256 amount)
    public
    virtual
    requiresAuth
  {
    TransferToken(token).transfer(comptrollerAddress(), amount);
  }

  receive() external payable virtual {
    this;
  }
}
