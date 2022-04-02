// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { Passport } from "@protocol/Passport.sol";
import { Authenticated, PayableMinter } from "./PayableMinter.sol";

contract PassportMinter is PayableMinter {
  Passport public immutable passport;

  constructor(
    address _authority,
    address _edn,
    address _passport
  ) Authenticated(_authority) PayableMinter(_edn) {
    passport = Passport(_passport);
  }

  function perform(bytes memory uri) external payable {
    if (passport.idOf(msg.sender) == 0) {
      passport.mintTo(msg.sender, uri);
    } else {
      passport.setTokenURI(passport.idOf(msg.sender), uri);
    }
    _mint(msg.value);
  }

  receive() external payable {
    if (passport.balanceOf(msg.sender) == 0) {
      passport.mintTo(msg.sender, "");
    }
    edn.mintTo(msg.sender, previewMint(msg.value));
  }
}
