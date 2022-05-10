// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, console} from "@test/ChainEnvironmentTest.t.sol";

import {Vault, VaultMock} from "@test/mocks/VaultMock.sol";

import {Reserve, ReserveVaultState} from "@protocol/Reserve.sol";

contract ReserveTest is ChainEnvironmentTest {
  Reserve public reserve;

  function setUp() public override {
    super.setUp();
    reserve = xtestCloneGas();
  }

  function xtestCloneGas() public pure returns (Reserve r) {
    r = Reserve(address(0));
    // r = bridge.createReserve(address(comptroller), address(dai), "DAI", "DAI");
  }

  function xtestCloneConstants() public {
    assertEq(reserve.MAX_STRATEGIES(), 20);
    assertEq(reserve.SET_SIZE(), 32);
  }

  function xtestNameAndSymbol() public {
    assertEq(reserve.name(), "DAI Eden Dao Reserve");
    assertEq(reserve.symbol(), "edn-DAI");
  }

  function xtestAddVault() public returns (VaultMock v) {
    v = new VaultMock(
      address(comptroller),
      address(reserve),
      "Mockingbird",
      "MOCK"
    );

    ReserveVaultState memory rs;
    rs.minDebtPerHarvest = 1e18;
    rs.maxDebtPerHarvest = 1e32;
    rs.performancePoints = 1000;
    rs.debtPoints = 1000;

    hevm.warp(256); // to set activationTimestamp != 0
    reserve.addVault(address(v), rs);
  }

  function xtestVaultHarvest() public {
    dai.mint(address(this), 1e24);
    dai.approve(address(reserve), 1e24);
    reserve.deposit(1e24, address(this));

    VaultMock v = xtestAddVault();
    (, , , , uint64 activationTimestamp, , , , ) = reserve.vaultStateOf(
      address(v)
    );
    assertTrue(activationTimestamp != 0);

    // reserve.depositTo(address(v));
    v.harvest(1e23, 0, 0);
  }

  function xtestDeposit(address caller, uint128 amount) public {
    hevm.assume(caller != address(this) && caller != address(0) && amount != 0);
    dai.mint(caller, amount);

    uint256 shares = reserve.previewDeposit(amount);

    hevm.startPrank(caller);
    dai.approve(address(reserve), amount);
    reserve.deposit(amount, caller);
    hevm.stopPrank();

    assertEq(reserve.balanceOf(caller), shares);
    assertEq(
      reserve.balanceOf(address(comptroller)), // beneficiary
      (shares * reserve.goodPoints()) / reserve.MAX_BPS()
    );
  }

  function xtestRedeem(address caller, uint128 amount) public {
    hevm.assume(caller != address(this) && caller != address(0) && amount != 0);
    dai.mint(caller, amount);

    hevm.startPrank(caller);
    dai.approve(address(reserve), amount);

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
