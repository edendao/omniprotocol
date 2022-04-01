// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import { PassportMinter } from "@protocol/actors/PassportMinter.sol";
import { TestBase } from "@protocol/test/TestBase.sol";

contract EDNTest is TestBase {
  function testOwnerCanMint(address _to, uint256 _amount) public {
    hevm.startPrank(owner);
    edn.mintTo(_to, _amount);
    hevm.stopPrank();
    assertEq(edn.balanceOf(_to), _amount);
  }

  function testFailMintTo(address _to, uint256 _amount) public {
    edn.mintTo(_to, _amount);
  }
}
