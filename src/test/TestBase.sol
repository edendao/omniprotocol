// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { console } from "forge-std/console.sol";
import { DSTestPlus } from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import { TreasuryAuthority } from "@protocol/TreasuryAuthority.sol";
import { EDN } from "@protocol/EDN.sol";
import { Passport } from "@protocol/Passport.sol";

contract TestBase is DSTestPlus {
  address internal owner = hevm.addr(42);

  TreasuryAuthority internal authority =
    new TreasuryAuthority(address(owner), address(0));

  EDN internal edn = new EDN(address(authority), address(0));
  Passport internal passport =
    new Passport(uint16(block.chainid), address(authority), address(0));
}
