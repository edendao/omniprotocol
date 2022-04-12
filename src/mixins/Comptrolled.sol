// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferFromToken} from "@protocol/interfaces/TransferFromToken.sol";

import {Comptroller} from "@protocol/Comptroller.sol";

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
    internal
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

  function withdrawToken(address token, uint256 idOrAmount)
    public
    requiresAuth
  {
    TransferFromToken(token).transferFrom(
      address(this),
      comptrollerAddress(),
      idOrAmount
    );
  }
}
