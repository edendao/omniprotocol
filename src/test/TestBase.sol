// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import { Comptroller } from "@protocol/Comptroller.sol";
import { EDN } from "@protocol/EDN.sol";
import { Passport } from "@protocol/Passport.sol";

contract TestBase is DSTestPlus {
  address internal myAddress = address(this);
  address internal owner = hevm.addr(42);

  Comptroller internal authority = new Comptroller(address(owner));

  EDN internal edn = new EDN(address(authority), address(0));
  Passport internal passport = new Passport(address(authority), address(0));
}
