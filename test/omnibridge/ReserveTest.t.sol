// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Reserve, MockERC20, console} from "@test/ChainEnvironmentTest.t.sol";

contract ReserveTest is ChainEnvironmentTest {
  function testCloneGas() public {
    Reserve r = bridge.createReserve(
      address(comptroller),
      address(note),
      "Frontier Carbon 2",
      "TIME2"
    );
    assertEq(r.symbol(), "edn-TIME2");
  }

  function testNameAndSymbol() public {
    assertEq(reserve.name(), "Frontier Carbon Eden Dao Reserve");
    assertEq(reserve.symbol(), "edn-TIME");
  }

  function testDeposit(address caller, uint128 amount) public {
    hevm.assume(caller != address(this) && caller != address(0) && amount != 0);
    note.mintTo(caller, amount);

    uint256 shares = reserve.previewDeposit(amount);

    hevm.startPrank(caller);
    note.approve(address(reserve), amount);
    reserve.deposit(amount, caller);
    hevm.stopPrank();

    assertEq(reserve.balanceOf(caller), shares);
    assertEq(
      reserve.balanceOf(address(comptroller)), // beneficiary
      (shares * reserve.goodPoints()) / reserve.MAX_BPS()
    );
  }

  function testRedeem(address caller, uint128 amount) public {
    hevm.assume(caller != address(this) && caller != address(0) && amount != 0);
    note.mintTo(caller, amount);

    hevm.startPrank(caller);
    note.approve(address(reserve), amount);

    uint256 shares = reserve.deposit(amount, caller);
    assertEq(reserve.balanceOf(caller), shares);
    assertEq(
      reserve.balanceOf(address(comptroller)), // beneficiary
      (shares * reserve.goodPoints()) / reserve.MAX_BPS()
    );

    reserve.redeem(shares, caller, caller);
    assertEq(reserve.balanceOf(caller), 0);
    hevm.stopPrank();
  }
}
