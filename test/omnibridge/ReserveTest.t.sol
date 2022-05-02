// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import {ChainEnvironmentTest} from "@test/ChainEnvironmentTest.t.sol";
import {Reserve} from "@protocol/omnibridge/Reserve.sol";

contract ReserveTest is ChainEnvironmentTest {
  MockERC20 internal fwaum =
    new MockERC20("Friends with Assets Under Management", "FWAUM", 18);
  Reserve internal reserve =
    new Reserve(
      address(this),
      address(this),
      address(fwaum),
      "Friends with Assets Under Management Vault",
      "edn-FWAUM"
    );

  function testDeposit(address caller, uint128 amount) public {
    hevm.assume(caller != address(this) && caller != address(0) && amount != 0);
    fwaum.mint(caller, amount);

    uint256 shares = reserve.previewDeposit(amount);

    hevm.startPrank(caller);
    fwaum.approve(address(reserve), amount);
    reserve.deposit(amount, caller);
    hevm.stopPrank();

    assertEq(reserve.balanceOf(caller), shares);
    assertEq(
      reserve.balanceOf(myAddress), // beneficiary
      (shares * reserve.goodPoints()) / reserve.MAX_BPS()
    );
  }
}
