// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
pragma abicoder v2;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";
import {Cloneable} from "@protocol/mixins/Cloneable.sol";
import {ERC20, ERC4626, SafeTransferLib} from "@protocol/mixins/ERC4626.sol";
import {Pausable} from "@protocol/mixins/Pausable.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";
import {ReentrancyGuard} from "@protocol/mixins/ReentrancyGuard.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {Vault} from "@protocol/mixins/Vault.sol";

struct ReserveVaultState {
  // Configuration
  uint256 minDebtPerHarvest;
  uint256 maxDebtPerHarvest;
  uint64 performancePoints;
  uint64 debtPoints;
  // Timestamps
  uint64 activationTimestamp;
  uint64 lastReportTimestamp;
  // Aggregates
  uint256 totalDebt;
  uint256 totalGain;
  uint256 totalLoss;
}

contract Reserve is ERC4626, PublicGood, Comptrolled, Cloneable, Pausable {
  using FixedPointMathLib for uint256;
  using SafeTransferLib for ERC20;

  uint8 public constant MAX_STRATEGIES = 20;
  uint8 public constant SET_SIZE = 32;

  address[MAX_STRATEGIES] public withdrawalQueue;
  event SetWithdrawalQueue(address[MAX_STRATEGIES] queue);

  mapping(address => ReserveVaultState) public vaultStateOf;
  event ReserveVaultStateUpsert(
    address indexed vault,
    uint64 performancePoints,
    uint64 debtPoints,
    uint256 minDebtPerHarvest,
    uint256 maxDebtPerHarvest
  );
  event ReserveVaultReport(
    address indexed vault,
    uint64 debtPoints,
    uint256 gain,
    uint256 loss,
    uint256 debtPaid,
    uint256 totalGain,
    uint256 totalLoss,
    uint256 totalDebt,
    uint256 debtAdded
  );

  uint256 public depositLimit;
  event SetDepositLimit(uint256 depositLimit);

  uint64 public debtPoints;
  uint64 public performancePoints;
  event SetPerformancePoints(uint64 performancePoints);

  uint64 public lastReportTimestamp;
  uint64 public activationTimestamp;

  uint256 public totalDebt;
  uint256 public lockedProfit;
  event BalanceUpdated(
    uint256 totalDebt,
    uint256 lockedProfit,
    uint256 debtPoints
  );

  // ================================
  // ========== Cloneable ===========
  // ================================
  function initialize(address _beneficiary, bytes calldata _params)
    external
    override
    initializer
  {
    (
      address _steward,
      address _asset,
      string memory _name,
      string memory _symbol
    ) = abi.decode(_params, (address, address, string, string));

    __initERC4626(ERC20(_asset));
    __initERC20(
      string(abi.encodePacked(_name, " Eden Dao Reserve")),
      string(abi.encodePacked("edn-", _symbol)),
      ERC20(_asset).decimals()
    );

    __initPublicGood(_beneficiary);
    __initComptrolled(_steward);

    performancePoints = 1000; // 10%
    emit SetPerformancePoints(performancePoints);

    lastReportTimestamp = uint64(block.timestamp);
    activationTimestamp = uint64(block.timestamp);
  }

  function clone(
    address _steward,
    address _asset,
    string memory _name,
    string memory _symbol
  ) external payable returns (address cloneAddress) {
    cloneAddress = clone();
    Cloneable(cloneAddress).initialize(
      beneficiary,
      abi.encode(_steward, _asset, _name, _symbol)
    );
  }

  // ================================
  // ========= Public Good ==========
  // ================================
  uint16 public constant MAX_BPS = 10_000;
  uint16 public goodPoints = 25; // 0.25% for the planet

  event SetGoodPoints(uint16 points);

  function setGoodPoints(uint16 basisPoints) external requiresAuth {
    require(
      10 <= basisPoints && basisPoints <= MAX_BPS,
      "PublicGood: INVALID_BP"
    );
    goodPoints = basisPoints;
    emit SetGoodPoints(basisPoints);
  }

  function _mint(address to, uint256 amount) internal override whenNotPaused {
    super._mint(to, amount);
  }

  // solhint-disable-next-line code-complexity
  function beforeWithdraw(uint256 assets, uint256)
    internal
    override
    whenNotPaused
  {
    address reserve = address(this);
    for (
      uint256 i = 0;
      asset.balanceOf(reserve) < assets && i < MAX_STRATEGIES;
      i++
    ) {
      uint256 balance = asset.balanceOf(reserve);
      address vaultAddress = withdrawalQueue[i];
      ReserveVaultState memory s = vaultStateOf[vaultAddress];
      ERC4626 vault = ERC4626(vaultAddress);
      uint256 withdrawableAmount = _min(vault.maxWithdraw(reserve), assets);

      vault.withdraw(withdrawableAmount, reserve, reserve);
      uint256 withdrawnAmount = asset.balanceOf(reserve) - balance;

      s.totalDebt -= withdrawnAmount;
      totalDebt -= withdrawnAmount;
      assets -= withdrawnAmount;

      if (withdrawnAmount < withdrawableAmount) {
        uint256 loss = withdrawableAmount - withdrawnAmount;
        s.totalLoss += loss;

        if (debtPoints != 0) {
          uint64 lossPoints = uint64(loss.mulDivDown(debtPoints, totalDebt));
          uint64 change = uint64(_min(s.debtPoints, lossPoints));
          if (change != 0) {
            s.debtPoints -= change;
            debtPoints -= change;
          }
        }
      }
    }
  }

  // Disable withdrawals of the underlying asset
  function withdrawToken(address token, uint256 amount) public override {
    require(token != address(asset), "Reserve: INVALID_TOKEN");
    TransferToken(token).transfer(address(authority), amount);
  }

  function totalShares() public view returns (uint256) {
    return previewDeposit(asset.balanceOf(address(this)) + totalDebt);
  }

  function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this)) + totalDebt - lockedProfit;
  }

  function setDepositLimit(uint256 limit) external requiresAuth {
    depositLimit = limit;
    emit SetDepositLimit(depositLimit);
  }

  function setPerformancePoints(uint64 points) external requiresAuth {
    require(points <= 500 && points <= MAX_BPS / 2, "Reserve: INVALID_BP");
    performancePoints = points;
    emit SetPerformancePoints(performancePoints);
  }

  function setWithdrawalQueue(address[MAX_STRATEGIES] memory queue)
    external
    requiresAuth
  {
    address[SET_SIZE] memory set;
    for (uint256 i = 0; i < MAX_STRATEGIES; i++) {
      address a = queue[i];

      if (a == address(0)) {
        require(withdrawalQueue[i] == address(0), "Reserve: CANNOT_REMOVE");
        break;
      }

      require(withdrawalQueue[i] != address(0), "Reserve: CANNOT_ADD");
      require(isActiveVault(a), "Reserve: INACTIVE_VAULT");

      uint256 key = uint256(uint160(a)) & (SET_SIZE - 1);
      for (uint256 j = 0; j < SET_SIZE; j++) {
        uint256 idx = (key + j) % SET_SIZE;
        require(set[idx] != a, "Reserve: DUPLICATE_VAULT");
        if (set[idx] == address(0)) {
          set[idx] = a;
          break;
        }
      }

      withdrawalQueue[i] = a;
    }

    emit SetWithdrawalQueue(queue);
  }

  modifier onlyValidState(ReserveVaultState memory state) {
    require(
      debtPoints + state.debtPoints <= MAX_BPS &&
        state.minDebtPerHarvest <= state.maxDebtPerHarvest &&
        state.performancePoints <= MAX_BPS / 2,
      "Reserve: INVALID_STATE"
    );
    _;
  }

  function addVault(address vault, ReserveVaultState memory initialState)
    external
    whenNotPaused
    onlyValidState(initialState)
  {
    require(vault != address(0), "Reserve: INVALID_ADDRESS");
    require(
      vaultStateOf[vault].activationTimestamp == 0,
      "Reserve: ACTIVE_VAULT"
    );
    require(
      address(asset) == address(ERC4626(vault).asset()),
      "Reserve: INVALID_ASSET"
    );
    require(
      withdrawalQueue[MAX_STRATEGIES - 1] == address(0),
      "Reserve: QUEUE_LIMIT"
    );

    uint64 timestamp = uint64(block.timestamp);
    vaultStateOf[vault] = initialState;
    vaultStateOf[vault].activationTimestamp = timestamp;
    vaultStateOf[vault].lastReportTimestamp = timestamp;

    emit ReserveVaultStateUpsert(
      vault,
      initialState.performancePoints,
      initialState.debtPoints,
      initialState.minDebtPerHarvest,
      initialState.maxDebtPerHarvest
    );

    debtPoints += initialState.debtPoints;
    withdrawalQueue[MAX_STRATEGIES - 1] = vault;
    _organizeWithdrawalQueue();
  }

  function isActiveVault(address vault) public view returns (bool) {
    return vaultStateOf[vault].activationTimestamp != 0;
  }

  modifier onlyActiveVault(address vault) {
    require(isActiveVault(vault), "Reserve: INACTIVE_VAULT");
    _;
  }

  function setVaultState(address vault, ReserveVaultState memory state)
    external
    requiresAuth
    onlyActiveVault(vault)
    onlyValidState(state)
  {
    ReserveVaultState storage s = vaultStateOf[vault];
    s.performancePoints = state.performancePoints;
    s.debtPoints = state.debtPoints;
    s.minDebtPerHarvest = state.minDebtPerHarvest;
    s.maxDebtPerHarvest = state.maxDebtPerHarvest;
  }

  function addVaultToQueue(address vault)
    external
    requiresAuth
    onlyActiveVault(vault)
  {
    uint256 i;
    for (i = 0; i < MAX_STRATEGIES; i++) {
      address s = withdrawalQueue[i];
      require(s != vault, "Reserve: ALREADY_QUEUED");
      if (s == address(0)) {
        break;
      }
    }
    require(i < MAX_STRATEGIES, "Reserve: QUEUE_LIMIT");
    withdrawalQueue[MAX_STRATEGIES - 1] = vault;
    _organizeWithdrawalQueue();
  }

  function removeVaultFromQueue(address vault) external requiresAuth {
    for (uint256 i = 0; i < MAX_STRATEGIES; i++) {
      if (withdrawalQueue[i] == vault) {
        withdrawalQueue[i] = address(0);
        _organizeWithdrawalQueue();
        break;
      }
    }
  }

  function debtOutstanding(address vault) public view returns (uint256) {
    ReserveVaultState memory s = vaultStateOf[vault];
    if (isPaused || debtPoints == 0) {
      return s.totalDebt;
    }

    uint256 vaultDebtLimit = (s.debtPoints * totalAssets()) / MAX_BPS;
    if (s.totalDebt <= vaultDebtLimit) {
      return 0;
    }

    return s.totalDebt - vaultDebtLimit;
  }

  function creditAvailable(address vault) public view returns (uint256) {
    if (isPaused) return 0;

    ReserveVaultState memory s = vaultStateOf[vault];
    uint256 reserveDebtLimit = totalAssets().mulDivDown(debtPoints, MAX_BPS);
    uint256 vaultDebt = s.totalDebt;
    uint256 vaultDebtLimit = totalAssets().mulDivDown(s.debtPoints, MAX_BPS);

    if (vaultDebtLimit <= vaultDebt || reserveDebtLimit <= totalDebt) {
      return 0;
    }

    uint256 availableDebt = _min(
      asset.balanceOf(address(this)),
      _min(vaultDebtLimit - vaultDebt, reserveDebtLimit - totalDebt)
    );

    if (availableDebt < s.minDebtPerHarvest) {
      return 0;
    }

    return _min(availableDebt, s.maxDebtPerHarvest);
  }

  // solhint-disable-next-line code-complexity
  function report(
    uint256 gain,
    uint256 loss,
    uint256 debtPayment
  ) external onlyActiveVault(msg.sender) returns (uint256 outstandingDebt) {
    require(
      asset.balanceOf(msg.sender) >= gain + debtPayment,
      "Reserve: INVALID_STATE"
    );
    ReserveVaultState storage s = vaultStateOf[msg.sender];

    if (loss > 0) {
      require(loss <= s.totalDebt, "Reserve: INVALID_LOSS");

      s.totalLoss += loss;
      s.totalDebt -= loss;
      totalDebt -= loss;

      if (debtPoints != 0) {
        uint64 lossPoints = uint64((loss * debtPoints) / totalDebt);
        uint64 change = uint64(_min(s.debtPoints, lossPoints));
        if (change != 0) {
          s.debtPoints -= change;
          debtPoints -= change;
        }
      }
    }

    s.totalGain += gain;
    uint256 availableCredit = creditAvailable(msg.sender);
    outstandingDebt = debtOutstanding(msg.sender);
    debtPayment = _min(debtPayment, outstandingDebt);

    if (debtPayment > 0) {
      s.totalDebt -= debtPayment;
      totalDebt -= debtPayment;
      outstandingDebt -= debtPayment;
    }

    if (availableCredit > 0) {
      s.totalDebt += availableCredit;
      totalDebt += availableCredit;
    }

    uint256 netAdditionalCapital = gain + debtPayment;
    if (netAdditionalCapital < availableCredit) {
      asset.safeTransfer(msg.sender, availableCredit - netAdditionalCapital);
    } else if (netAdditionalCapital > availableCredit) {
      asset.safeTransferFrom(
        msg.sender,
        address(this),
        netAdditionalCapital - availableCredit
      );
    }

    uint256 publicGoodGains;
    uint256 strategistGains;
    if (
      gain == 0 ||
      s.activationTimestamp == block.timestamp || // Only valid for active contracts
      s.lastReportTimestamp != block.timestamp // Only valid for this timestamp
    ) {
      publicGoodGains = 0;
      strategistGains = 0;
    } else {
      publicGoodGains = gain.mulDivDown(performancePoints, MAX_BPS);
      strategistGains = gain.mulDivDown(s.performancePoints, MAX_BPS);
    }

    uint256 performanceFees = publicGoodGains + strategistGains;
    if (performanceFees != 0) {
      uint256 reward = previewDeposit(performanceFees);
      uint256 strategistReward = strategistGains.mulDivDown(
        reward,
        performanceFees
      );
      uint256 publicGoodReward = reward - strategistReward;

      if (publicGoodReward > 0) {
        _mint(beneficiary, publicGoodReward);
      }
      if (strategistReward > 0) {
        _mint(msg.sender, strategistReward);
      }
    }

    uint256 lockedProfitBeforeLoss = lockedProfit + gain - performanceFees;

    lockedProfit = loss > lockedProfitBeforeLoss
      ? 0
      : lockedProfitBeforeLoss - loss;
    lastReportTimestamp = s.lastReportTimestamp = uint64(block.timestamp);

    emit ReserveVaultReport(
      msg.sender,
      s.debtPoints,
      gain,
      loss,
      debtPayment,
      s.totalGain,
      s.totalLoss,
      s.totalDebt,
      availableCredit
    );

    // When paused or when revoked vault should return all assets
    if (isPaused || s.debtPoints == 0) {
      return ERC4626(msg.sender).totalAssets();
    }

    return outstandingDebt;
  }

  function _organizeWithdrawalQueue() internal {
    uint256 offset = 0;
    for (uint256 i = 0; i < MAX_STRATEGIES; i++) {
      address vault = withdrawalQueue[i];
      if (vault == address(0)) {
        offset += 1;
      } else if (offset > 0) {
        withdrawalQueue[i - offset] = vault;
        withdrawalQueue[i] = address(0);
      }
    }
    emit SetWithdrawalQueue(withdrawalQueue);
  }

  function _max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? b : a;
  }
}
