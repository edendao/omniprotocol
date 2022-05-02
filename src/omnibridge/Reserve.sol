// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

import {ERC20, ERC4626} from "@protocol/mixins/ERC4626.sol";

import {Note, Comptrolled} from "@protocol/omnibridge/Note.sol";

contract Reserve is Note, ERC4626 {
  using SafeTransferLib for ERC20;

  uint8 public constant MAXIMUM_STRATEGIES = 20;
  uint8 public constant SET_SIZE = 32;
  uint32 public constant SECS_PER_YEAR = 31_556_952;

  mapping(address => StrategyParams) public strategies;
  address[MAXIMUM_STRATEGIES] public withdrawalQueue;
  event UpdateWithdrawalQueue(address[20] queue);

  uint64 public debtBasisPoints;
  uint64 public performanceBasisPoints;
  event UpdatePerformanceBasisPoints(uint64 performanceBasisPoints);
  uint64 public lastReportTimestamp;
  uint64 public activationTimestamp;
  uint256 public depositLimit;
  event UpdateDepositLimit(uint256 depositLimit);
  uint256 public totalDebt;
  uint256 public lockedProfit;

  address public guardian;
  event UpdateGuardian(address guardian);
  address public healthCheck;
  event UpdateHealthCheck(address healthCheck);

  struct StrategyParams {
    uint64 performanceBasisPoints;
    uint64 activationTimestamp;
    uint64 debtBasisPoints;
    uint64 lastReportTimestamp;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
  }

  event StrategyUpsert(
    address indexed strategy,
    uint64 performanceBasisPoints,
    uint64 debtBasisPoints,
    uint256 minDebtPerHarvest,
    uint256 maxDebtPerHarvest
  );

  event StrategyReport(
    address indexed strategy,
    uint256 gain,
    uint256 loss,
    uint256 debtPaid,
    uint256 totalGain,
    uint256 totalLoss,
    uint256 totalDebt,
    uint256 debtAdded,
    uint64 debtBasisPoints
  );

  event Sweep(address indexed token, uint256 amount);

  constructor(
    address _comptroller,
    address _beneficiary,
    address _underlying,
    string memory _name,
    string memory _symbol
  )
    Note(
      _comptroller,
      _beneficiary,
      string(abi.encodePacked(_name, " Eden Dao Vault")),
      string(abi.encodePacked("edn-", _symbol)),
      ERC20(_underlying).decimals()
    )
    ERC4626(ERC20(_underlying))
  {
    performanceBasisPoints = 1000; // 10%
    emit UpdatePerformanceBasisPoints(performanceBasisPoints);

    // healthCheck = _healthCheck;
    // emit UpdateHealthCheck(healthCheck);

    lastReportTimestamp = uint64(block.timestamp);
    activationTimestamp = uint64(block.timestamp);
  }

  function setHealthCheck(address _healthCheck) external requiresAuth {
    healthCheck = _healthCheck;
    emit UpdateHealthCheck(healthCheck);
  }

  function setDepositLimit(uint256 limit) external requiresAuth {
    depositLimit = limit;
    emit UpdateDepositLimit(depositLimit);
  }

  function setPerformanceBasisPoints(uint64 basisPoints) external requiresAuth {
    require(basisPoints <= MAX_BPS / 2, "Reserve: INVALID_BP");
    performanceBasisPoints = basisPoints;
    emit UpdatePerformanceBasisPoints(performanceBasisPoints);
  }

  function setWithdrawalQueue(address[MAXIMUM_STRATEGIES] memory queue)
    external
    requiresAuth
  {
    address[SET_SIZE] memory set;
    for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
      if (queue[i] == address(0)) {
        require(withdrawalQueue[i] == address(0), "Vault: UNAUTHORIZED");
        break;
      }

      require(withdrawalQueue[i] != address(0), "Vault: UNAUTHORIZED");
      require(
        strategies[queue[i]].activationTimestamp != 0,
        "Vault: INACTIVE_STRATEGY"
      );
      uint256 key = uint256(uint160(queue[i])) & (SET_SIZE - 1);
      for (uint256 j = 0; j < SET_SIZE; j++) {
        uint256 idx = (key + j) % SET_SIZE;
        require(set[idx] != queue[i], "Vault: DUPLICATE_STRATEGY");
        if (set[idx] == address(0)) {
          set[idx] = queue[i];
          break;
        }
      }

      withdrawalQueue[i] = queue[i];
    }

    emit UpdateWithdrawalQueue(queue);
  }

  function totalShares() public view returns (uint256) {
    return previewDeposit(totalAssets());
  }

  function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this)) + totalDebt - lockedProfit;
  }

  function _reportLoss(address strategy, uint256 loss) internal {
    uint256 strategyDebt = strategies[strategy].totalDebt;
    require(strategyDebt >= loss, "Vault: INVALID_LOSS");
    if (debtBasisPoints != 0) {
      uint64 strategyDebtBasisPoints = strategies[strategy].debtBasisPoints;
      uint64 lossBasisPoints = uint64((loss * debtBasisPoints) / totalDebt);
      uint64 change = uint64(_min(strategyDebtBasisPoints, lossBasisPoints));
      if (change != 0) {
        strategies[strategy].debtBasisPoints -= change;
        debtBasisPoints -= change;
      }
    }
    strategies[strategy].totalLoss += loss;
    strategies[strategy].totalDebt = strategyDebt - loss;
    totalDebt -= loss;
  }

  modifier isActiveStrategy(address strategy) {
    require(
      strategies[strategy].activationTimestamp != 0,
      "Reserve: INACTIVE_STRATEGY"
    );
    _;
  }

  function addStrategy(address strategy, StrategyParams memory params)
    external
    whenNotPaused
  {
    require(
      withdrawalQueue[MAXIMUM_STRATEGIES - 1] == address(0),
      "Reserve: QUEUE_LIMIT"
    );
    require(
      strategy != address(0) &&
        strategies[strategy].activationTimestamp == 0 &&
        address(asset) == address(ERC4626(strategy).asset()),
      "Reserve: INVALID_STRATEGY"
    );
    require(
      debtBasisPoints + params.debtBasisPoints <= MAX_BPS &&
        params.minDebtPerHarvest <= params.maxDebtPerHarvest &&
        params.performanceBasisPoints <= MAX_BPS / 2,
      "Reserve: INVALID_PARAMS"
    );
    params.lastReportTimestamp = uint64(block.timestamp);
    strategies[strategy] = params;
    emit StrategyUpsert(
      strategy,
      params.performanceBasisPoints,
      params.debtBasisPoints,
      params.minDebtPerHarvest,
      params.maxDebtPerHarvest
    );

    debtBasisPoints += params.debtBasisPoints;
    withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy;
    _organizeWithdrawalQueue();
  }

  function updateStrategy(address strategy, StrategyParams memory params)
    external
    requiresAuth
  {
    require(
      strategies[strategy].activationTimestamp > 0,
      "Reserve: INACTIVE_STRATEGY"
    );
    require(
      debtBasisPoints + params.debtBasisPoints <= MAX_BPS &&
        params.minDebtPerHarvest <= params.maxDebtPerHarvest &&
        params.performanceBasisPoints <= MAX_BPS / 2,
      "Reserve: INVALID_PARAMS"
    );
    emit StrategyUpsert(
      strategy,
      params.performanceBasisPoints,
      params.debtBasisPoints,
      params.minDebtPerHarvest,
      params.maxDebtPerHarvest
    );
  }

  function revokeStrategy(address strategy) external {
    if (strategies[strategy].debtBasisPoints != 0) {
      _revokeStrategy(strategy);
    }
  }

  function addStrategyToQueue(address strategy)
    external
    requiresAuth
    isActiveStrategy(strategy)
  {
    uint256 i;
    for (i = 0; i < MAXIMUM_STRATEGIES; i++) {
      address s = withdrawalQueue[i];
      require(s != strategy, "Reserve: ALREADY_QUEUED");
      if (s == address(0)) {
        break;
      }
    }
    require(i < MAXIMUM_STRATEGIES, "Reserve: QUEUE_LIMIT");
    withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy;
    _organizeWithdrawalQueue();
  }

  function removeStrategyFromQueue(address strategy) external requiresAuth {
    for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
      if (withdrawalQueue[i] == strategy) {
        withdrawalQueue[i] = address(0);
        _organizeWithdrawalQueue();
        break;
      }
    }
  }

  function debtOutstanding(address strategy) public view returns (uint256) {
    uint256 strategyDebt = strategies[strategy].totalDebt;
    if (isPaused || debtBasisPoints == 0) {
      return strategyDebt;
    }

    uint256 strategyDebtLimit = (strategies[strategy].debtBasisPoints *
      totalAssets()) / MAX_BPS;

    if (strategyDebt <= strategyDebtLimit) {
      return 0;
    }

    return strategyDebt - strategyDebtLimit;
  }

  function creditAvailable(address strategy) public view returns (uint256) {
    if (isPaused) return 0;

    uint256 reserveDebtLimit = _mulDivDown(
      totalAssets(),
      debtBasisPoints,
      MAX_BPS
    );
    uint256 strategyDebt = strategies[strategy].totalDebt;
    uint256 strategyDebtLimit = _mulDivDown(
      totalAssets(),
      strategies[strategy].debtBasisPoints,
      MAX_BPS
    );

    if (strategyDebtLimit <= strategyDebt || reserveDebtLimit <= totalDebt) {
      return 0;
    }

    uint256 availableDebt = _min(
      asset.balanceOf(address(this)),
      _min(strategyDebtLimit - strategyDebt, reserveDebtLimit - totalDebt)
    );

    if (availableDebt < strategies[strategy].minDebtPerHarvest) {
      return 0;
    }

    return _min(availableDebt, strategies[strategy].maxDebtPerHarvest);
  }

  function expectedReturn(address strategy) public view returns (uint256) {
    StrategyParams memory p = strategies[strategy];
    uint256 timeSinceHarvest = block.timestamp - p.lastReportTimestamp;
    uint256 totalHarvestTime = p.lastReportTimestamp - p.activationTimestamp;

    if (timeSinceHarvest == 0 || totalHarvestTime == 0) {
      return 0;
    }

    return _mulDivDown(p.totalGain, timeSinceHarvest, totalHarvestTime);
  }

  function _assessFees(address strategy, uint256 gain)
    internal
    returns (uint256)
  {
    StrategyParams memory p = strategies[strategy];
    if (gain == 0 || p.activationTimestamp == block.timestamp) {
      return 0;
    }

    uint256 duration = block.timestamp - p.lastReportTimestamp;
    require(duration != 0, "Reserve: INVARIANT");

    uint256 performanceFee = _mulDivDown(gain, performanceBasisPoints, MAX_BPS);
    uint256 strategistFee = _mulDivDown(
      gain,
      p.performanceBasisPoints,
      MAX_BPS
    );
    uint256 totalFee = performanceFee + strategistFee;
    if (totalFee > gain) {
      totalFee = gain;
    }

    if (totalFee > 0) {
      uint256 totalReward = previewDeposit(totalFee);
      uint256 strategistReward = _mulDivDown(
        strategistFee,
        totalReward,
        totalFee
      );
      uint256 performanceReward = totalReward - strategistReward;

      if (strategistReward > 0) {
        _mint(strategy, strategistReward);
      }

      if (performanceReward > 0) {
        _mint(beneficiary, performanceReward);
      }
    }

    return totalFee;
  }

  function report(
    uint256 gain,
    uint256 loss,
    uint256 debtPayment
  ) external isActiveStrategy(msg.sender) returns (uint256) {
    require(
      asset.balanceOf(msg.sender) >= gain + debtPayment,
      "Reserve: INVALID_PARAMS"
    );
    if (loss > 0) {
      _reportLoss(msg.sender, loss);
    }

    uint256 totalFees = _assessFees(msg.sender, gain);

    StrategyParams storage p = strategies[msg.sender];
    p.totalGain += gain;
    uint256 credit = creditAvailable(msg.sender);
    uint256 debt = debtOutstanding(msg.sender);
    debtPayment = _min(debtPayment, debt);

    if (debtPayment > 0) {
      p.totalDebt -= debtPayment;
      totalDebt -= debtPayment;
      debt -= debtPayment;
    }

    if (credit > 0) {
      p.totalDebt += credit;
      totalDebt += credit;
    }

    uint256 totalAvailable = gain + debtPayment;
    if (totalAvailable < credit) {
      asset.safeTransfer(msg.sender, credit - totalAvailable);
    } else if (totalAvailable > credit) {
      asset.safeTransferFrom(
        msg.sender,
        address(this),
        totalAvailable - credit
      );
    }

    uint256 lockedProfitBeforeLoss = lockedProfit + gain - totalFees;
    lockedProfit = lockedProfitBeforeLoss > loss
      ? lockedProfitBeforeLoss - loss
      : 0;

    p.lastReportTimestamp = uint64(block.timestamp);
    lastReportTimestamp = uint64(block.timestamp);

    emit StrategyReport(
      msg.sender,
      gain,
      loss,
      debtPayment,
      p.totalGain,
      p.totalLoss,
      p.totalDebt,
      credit,
      p.debtBasisPoints
    );

    if (p.debtBasisPoints != 0 && !isPaused) {
      return debt;
    } else {
      return ERC4626(msg.sender).totalAssets();
    }
  }

  function withdrawToken(address token, uint256 amount) public override {
    require(token != address(asset), "Reserve: INVALID_TOKEN");
    super.withdrawToken(token, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20, Note) {
    super._mint(to, amount);
  }

  function _revokeStrategy(address strategy) internal {
    StrategyParams storage p = strategies[strategy];
    debtBasisPoints -= p.debtBasisPoints;
    p.debtBasisPoints = 0;

    emit StrategyUpsert(
      strategy,
      p.performanceBasisPoints,
      p.debtBasisPoints,
      p.minDebtPerHarvest,
      p.maxDebtPerHarvest
    );
  }

  function _organizeWithdrawalQueue() internal {
    uint256 offset = 0;
    for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
      address strategy = withdrawalQueue[i];
      if (strategy == address(0)) {
        offset += 1;
      } else if (offset > 0) {
        withdrawalQueue[i - offset] = strategy;
        withdrawalQueue[i] = address(0);
      }
    }
    emit UpdateWithdrawalQueue(withdrawalQueue);
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? b : a;
  }
}
