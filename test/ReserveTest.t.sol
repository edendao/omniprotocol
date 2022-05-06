// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest, Reserve, MockERC20, console} from "@test/ChainEnvironmentTest.t.sol";

import {Vault} from "@protocol/mixins/Vault.sol";
import {ReserveVaultState} from "@protocol/Reserve.sol";

contract MockVault is Vault {
  constructor(
    address _comptroller,
    address _asset,
    address _reserve,
    string memory _name,
    string memory _symbol
  ) {
    __initVault(_comptroller, _asset, _reserve);
    __initERC20(_name, _symbol, 18);
  }

  function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this));
  }

  function harvest() external view override {
    this;
  }

  function harvestable() external pure override returns (bool) {
    return false;
  }
}

contract ReserveTest is ChainEnvironmentTest {
  Reserve public reserve;

  function setUp() public override {
    super.setUp();
    reserve = testCloneGas();
  }

  function testCloneGas() public returns (Reserve r) {
    r = bridge.createReserve(address(comptroller), address(dai), "DAI", "DAI");
  }

  function testCloneConstants() public {
    assertEq(reserve.MAX_STRATEGIES(), 20);
    assertEq(reserve.SET_SIZE(), 32);
  }

  function testNameAndSymbol() public {
    assertEq(reserve.name(), "DAI Eden Dao Reserve");
    assertEq(reserve.symbol(), "edn-DAI");
  }

  function testAddVault() public {
    Vault s = new MockVault(
      address(comptroller),
      address(dai),
      address(reserve),
      "Mockingbird",
      "MOCK"
    );

    ReserveVaultState memory rs;
    rs.minDebtPerHarvest = 100;
    rs.maxDebtPerHarvest = 1000000000;
    rs.performancePoints = 1000;
    rs.debtPoints = 1000;

    reserve.addVault(address(s), rs);

    hevm.label(address(reserve), "edn-DAI");
  }

  function testDeposit(address caller, uint128 amount) public {
    hevm.assume(caller != address(this) && caller != address(0) && amount != 0);
    dai.mintTo(caller, amount);

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

  function testRedeem(address caller, uint128 amount) public {
    hevm.assume(caller != address(this) && caller != address(0) && amount != 0);
    dai.mintTo(caller, amount);

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
