// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ERC20} from "@protocol/mixins/ERC20.sol";
import {ERC4626} from "@protocol/mixins/ERC4626.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";

import {Reserve, ReserveVaultState} from "@protocol/Reserve.sol";

abstract contract Vault is Comptrolled, Pausable, ERC4626 {
  Reserve public reserve;

  function __initVault(address _steward, address _reserve) internal {
    reserve = Reserve(_reserve);

    __initERC4626(reserve.asset());
    __initComptrolled(_steward);

    asset.approve(_reserve, type(uint256).max); // for managing assets
    reserve.approve(_steward, type(uint256).max); // for withdrawing rewards
  }

  uint64 public minHarvestDelay;
  uint64 public maxHarvestDelay;
  uint256 public debtThreshold;

  event Harvested(
    uint256 profit,
    uint256 loss,
    uint256 debtPayment,
    uint256 debtOutstanding
  );

  function totalAssets() public view virtual override returns (uint256) {
    return asset.balanceOf(address(this)); // add up balances across strategies
  }

  function debtOutstanding() public view returns (uint256) {
    return reserve.debtOutstanding(address(this));
  }

  function beforeWithdraw(uint256 assets, uint256) internal virtual override {
    // Withdraw assets from strategies
  }

  function afterDeposit(uint256 assets, uint256) internal virtual override {
    // Deposit assets into yield strategies
  }

  // Return `true` if the position ought to be tended
  function tendable() external virtual returns (bool) {
    return false;
  }

  /**
   * @notice
   *  Adjust the Strategy's position. The purpose of tending isn't to
   *  realize gains, but to maximize yield by reinvesting any returns.
   */
  function tend() external virtual requiresAuth {
    _adjustPosition(debtOutstanding());
  }

  // Return `true` if the position ought to be harvested
  function harvestable() external virtual returns (bool) {
    (
      ,
      ,
      ,
      ,
      uint64 activationTimestamp,
      uint64 lastReportTimestamp,
      uint256 totalDebt,
      ,

    ) = reserve.vaultStateOf(address(this));

    if (activationTimestamp == 0) return false;

    uint64 timeSinceHarvest = uint64(block.timestamp) - lastReportTimestamp;
    if (timeSinceHarvest < minHarvestDelay) return false;
    if (timeSinceHarvest >= maxHarvestDelay) return true;

    if (debtOutstanding() > debtThreshold) return true;

    uint256 total = totalAssets();
    if (total < totalDebt - debtThreshold) return true;

    uint256 profit = 0;
    if (total > totalDebt) profit = total - totalDebt;

    uint256 credit = reserve.creditAvailable(address(this));
    return 0.2 ether < (profit + credit);
  }

  /**
   * @notice
   *  Harvests the Vault, recognizing any profits or losses and adjusting
   *  the Vault's position.
   *
   *  In the rare case the Vault is in emergency shutdown, this will exit
   *  the Vault's position.
   *
   *  This may only be called by governance, the strategist, or the keeper.
   * @dev
   *  When `harvest()` is called, the Vault reports to the Vault (via
   *  `reserve.report()`), so in some cases `harvest()` must be called in order
   *  to take in profits, to borrow newly available funds from the Vault, or
   *  otherwise adjust its position. In other cases `harvest()` must be
   *  called to report to the Vault on the Vault's position, especially if
   *  any losses have occurred.
   */
  function harvest() external virtual requiresAuth {
    uint256 profit = 0;
    uint256 loss = 0;
    uint256 outstandingDebt = debtOutstanding();
    uint256 debtPayment = 0;

    if (isPaused) {
      (uint256 amountFreed, ) = _liquidateAllPositions();
      if (amountFreed > outstandingDebt) {
        profit = amountFreed - outstandingDebt;
      } else if (amountFreed < outstandingDebt) {
        loss = outstandingDebt - amountFreed;
      }
      debtPayment = outstandingDebt - loss;
    } else {
      (profit, loss, debtPayment) = _prepareReturn(outstandingDebt);
    }

    outstandingDebt = reserve.report(profit, loss, debtPayment);

    _adjustPosition(outstandingDebt);

    emit Harvested(profit, loss, debtPayment, outstandingDebt);
  }

  /**
   * Perform any adjustments to the core position(s) of this Vault given
   * what change the Vault made in the "investable capital" available to the
   * Vault. Note that all "free capital" in the Vault after the report
   * was made is available for reinvestment. Also note that this number
   * could be 0, and you should handle that scenario accordingly.
   *
   * See comments regarding `_debtOutstanding` on `prepareReturn()`.
   */
  function _adjustPosition(uint256 outstandingDebt) internal virtual;

  /**
   * Liquidate everything. This function is used during emergency exit instead
   * of `prepareReturn()` to liquidate all of the Vault's positions back to
   * the Vault. MUST perserve `amountFreed + realizedLoss <= amountNeeded`.
   */
  function _liquidateAllPositions()
    internal
    virtual
    returns (uint256 amountFreed, uint256 realizedLoss);

  /**
   * Perform any Vault unwinding or other calls necessary to capture the
   * "free return" this Vault has generated since the last time its core
   * position(s) were adjusted. Examples include unwrapping extra rewards.
   * This call is only used during "normal operation" of a Vault, and
   * should be optimized to minimize losses as much as possible.
   *
   * This method returns any realized profits and/or realized losses
   * incurred, and should return the total amounts of profits/losses/debt
   * payments (in `asset` tokens) for the Vault's accounting (e.g.
   * `asset.balanceOf(this) >= debtPayment + profit`).
   *
   * `outstandingDebt` will be 0 if the Vault is not past the configured
   * debt limit, otherwise its value will be how far past the debt limit
   * the Vault is. The Vault's debt limit is configured in the Vault.
   *
   * NOTE: `debtPayment` should be less than or equal to `outstandingDebt`.
   *       It is okay for it to be less than `outstandingDebt`, as that
   *       should only used as a guide for how much is left to pay back.
   *       Payments should be made to minimize loss from slippage, debt,
   *       withdrawal fees, etc.
   *
   * See `reserve.debtOutstanding()`.
   */
  function _prepareReturn(uint256 outstandingDebt)
    internal
    virtual
    returns (
      uint256 profit,
      uint256 realizedLoss,
      uint256 debtPayment
    );

  /**
   * Do anything necessary to prepare this Vault for migration, such as
   * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
   * value.
   */
  function _prepareMigration(Vault newVault) internal virtual;

  function migrate(address newVaultAddress) external requiresAuth {
    Vault newVault = Vault(newVaultAddress);
    require(newVault.reserve() == reserve, "Vault: INVALID_RESERVE");

    _prepareMigration(newVault);
    newVault.deposit(asset.balanceOf(address(this)), address(reserve));
  }
}
