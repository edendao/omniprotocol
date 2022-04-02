// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { EDN } from "@protocol/EDN.sol";
import { Passport } from "@protocol/Passport.sol";

contract PassportMinter {
  EDN public immutable edn;
  Passport public immutable passport;

  constructor(address _edn, address _passport) {
    edn = EDN(_edn);
    passport = Passport(_passport);
  }

  function previewMint(uint256 _amountInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * EDN.decimals()
    return _amountInWei / 10**12;
  }

  receive() external payable {
    if (passport.balanceOf(msg.sender) == 0) {
      passport.mintTo(msg.sender);
    }
    edn.mintTo(msg.sender, previewMint(msg.value));
  }
}
