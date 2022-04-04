// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { EDN } from "@protocol/EDN.sol";
import { Passport } from "@protocol/Passport.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";

contract PassportMinter is Authenticated {
  EDN public immutable edn;
  Passport public immutable passport;

  constructor(
    address _authority,
    address _edn,
    address _passport
  ) Authenticated(_authority) {
    edn = EDN(_edn);
    passport = Passport(_passport);
  }

  function preview(uint256 valueInWei) public pure returns (uint256) {
    // 10**12 = 10**3 / 10**18 * 10**12 = exchangeRate() / ETH.decimals() * EDN.decimals()
    return valueInWei / 10**12;
  }

  function perform(bytes memory uri) external payable {
    passport.ensureMintedTo(msg.sender);
    passport.setTokenURI(passport.idOf(msg.sender), uri);
    edn.mintTo(msg.sender, preview(msg.value));
  }

  receive() external payable {
    passport.ensureMintedTo(msg.sender);
    edn.mintTo(msg.sender, preview(msg.value));
  }

  function withdraw() external {
    payable(owner).transfer(address(this).balance);
  }
}
