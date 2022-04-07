// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { Authenticated } from "@protocol/mixins/Authenticated.sol";

import { Passport } from "@protocol/Passport.sol";

contract NiftyOmnifity is Authenticated {
  Passport internal passport;

  constructor(address _authority, address _passport) Authenticated(_authority) {
    passport = Passport(_passport);
  }

  function cast(address owner, bytes memory data)
    external
    requiresAuth
    returns (uint256)
  {
    uint256 passportId = passport.findOrMintFor(owner);
    passport.setData(passportId, passport.TOKEN_URI_DOMAIN(), data);
    return passportId;
  }
}
