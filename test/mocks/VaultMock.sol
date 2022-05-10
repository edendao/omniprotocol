// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Vault} from "@protocol/mixins/Vault.sol";

contract VaultMock is Vault {
  constructor(
    address _comptroller,
    address _reserve,
    string memory _name,
    string memory _symbol
  ) {
    __initVault(_comptroller, _reserve);
    __initERC20(_name, _symbol, 18);
  }

  function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this));
  }

  function tend() external pure override {
    revert("VaultMock: NOT_IMPLEMENTED");
  }

  function tendable() external pure override returns (bool) {
    return false;
  }

  function harvestable() external pure override returns (bool) {
    return false;
  }

  function harvest(
    uint256 gain,
    uint256 loss,
    uint256 debtPayment
  ) external {
    reserve.report(gain, loss, debtPayment);
  }

  function _adjustPosition(uint256 outstandingDebt) internal pure override {}

  function _liquidateAllPositions()
    internal
    pure
    override
    returns (uint256 amountFreed, uint256 realizedLoss)
  {
    return (0, 0);
  }

  function _prepareReturn(uint256)
    internal
    pure
    override
    returns (
      uint256 profit,
      uint256 realizedLoss,
      uint256 debtPayment
    )
  {
    return (0, 0, 0);
  }

  function _prepareMigration(Vault) internal pure override {}
}
