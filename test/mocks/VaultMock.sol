// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Vault} from "@protocol/mixins/Vault.sol";

contract VaultMock is Vault {
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

  function tend() external pure override {
    revert("VaultMock: NOT_IMPLEMENTED");
  }

  function tendable() external pure override returns (bool) {
    return false;
  }

  function harvest() external pure override {
    revert("VaultMock: NOT_IMPLEMENTED");
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
}
