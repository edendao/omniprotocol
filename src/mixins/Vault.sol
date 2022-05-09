// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {ERC20, ERC4626} from "@protocol/mixins/ERC4626.sol";

import {Reserve} from "@protocol/Reserve.sol";

// Mix in the Vault contract to build your own!
abstract contract Vault is Comptrolled, ERC4626 {
  Reserve public reserve;

  event Harvested(
    uint256 profit,
    uint256 loss,
    uint256 debtPayment,
    uint256 debtOutstanding
  );

  function __initVault(
    address _comptroller,
    address _asset,
    address _reserve
  ) internal {
    _setComptroller(_comptroller);
    __initERC4626(ERC20(_asset));
    reserve = Reserve(_reserve);

    asset.approve(_reserve, type(uint256).max);
  }

  // function totalAssets() public view override returns (uint256);

  // Withdraw assets from yield strategies
  // function beforeWithdraw(uint256 assets, uint256) internal virtual;

  // Deposit assets into yield strategies
  // function afterDeposit(uint256 assets, uint256) internal virtual;

  // Harvests the Strategy, recognizing any profits or losses and adjusting
  // the Strategy's position.
  //
  // In the rare case the Strategy is in emergency shutdown, this will exit
  // the Strategy's position.
  function tend() external virtual;

  // Is it valuable to tend?
  function tendable() external virtual returns (bool);

  // Harvests the Strategy, recognizing any profits or losses and adjusting
  // the Strategy's position.
  //
  // In the rare case the Strategy is in emergency shutdown, this will exit
  // the Strategy's position.
  function harvest() external virtual;

  // Is it valuable to harvest?
  function harvestable() external virtual returns (bool);
}
