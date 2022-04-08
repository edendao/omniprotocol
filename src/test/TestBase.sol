// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import {Comptroller} from "@protocol/Comptroller.sol";
import {Note} from "@protocol/Note.sol";
import {Passport} from "@protocol/Passport.sol";
import {Domain} from "@protocol/Domain.sol";

contract TestBase is DSTestPlus {
  address internal myAddress = address(this);
  address internal owner = hevm.addr(42);

  Comptroller internal authority = new Comptroller(address(owner));

  Note internal edn = new Note(address(authority), address(0));
  Domain internal dns =
    new Domain(address(authority), address(0), uint16(block.chainid));
  Passport internal pass =
    new Passport(address(authority), address(0), address(dns));
}
