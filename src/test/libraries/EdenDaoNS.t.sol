// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {DSTestPlus} from "@rari-capital/solmate/test/utils/DSTestPlus.sol";

import {EdenDaoNS} from "@protocol/libraries/EdenDaoNS.sol";

contract EdenDaoNSTest is DSTestPlus {
  function testNamehash() public {
    assertEq(
      0x5390756d6822bfddf4c057851c400cc27c97960f67128fa42a6d838b35584b8c,
      EdenDaoNS.namehash("name")
    );

    assertEq(
      0x1de324d049794c1e40480a9129c30e42d9ada5968d6e81df7b8b9c0fa838251f,
      EdenDaoNS.namehash("tokenuri")
    );

    assertEq(
      0x695420e367ddca8aab0a4c1cab3509b641bc5ecf7bd8b177ce2f50d52c7ae64b,
      EdenDaoNS.namehash("prosperity")
    );
  }
}
