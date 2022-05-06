// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";
import {ReentrancyGuard} from "@protocol/mixins/ReentrancyGuard.sol";
import {ERC20, ERC4626, SafeTransferLib} from "@protocol/mixins/ERC4626.sol";
import {Cloneable} from "@protocol/mixins/Cloneable.sol";
import {Vault} from "@protocol/mixins/Vault.sol";
import {Note} from "@protocol/Note.sol";

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

contract Reserve is Note, ERC4626 {
  using FixedPointMathLib for uint256;
  using SafeTransferLib for ERC20;

  uint8 public constant MAX_STRATEGIES = 20;
  uint8 public constant SET_SIZE = 32;

  uint64 public debtPoints;
  uint64 public performancePoints;
  event UpdatePerformancePoints(uint64 performancePoints);
  uint64 public lastReportTimestamp;
  uint64 public activationTimestamp;
  uint256 public depositLimit;
  event UpdateDepositLimit(uint256 depositLimit);
  uint256 public totalDebt;
  uint256 public lockedProfit;

  mapping(address => ReserveVaultState) public vaults;

  address[MAX_STRATEGIES] public withdrawalQueue;
  event UpdateWithdrawalQueue(address[MAX_STRATEGIES] queue);

  event ReserveVaultStateUpsert(
    address indexed vault,
    uint64 performancePoints,
    uint64 debtPoints,
    uint256 minDebtPerHarvest,
    uint256 maxDebtPerHarvest
  );

  event ReserveVaultStateReport(
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

  function initialize(address _beneficiary, bytes calldata _params)
    external
    override(Cloneable, Note)
    initializer
  {
    (
      address _comptroller,
      address _asset,
      string memory _name,
      string memory _symbol
    ) = abi.decode(_params, (address, address, string, string));
    __initPublicGood(_beneficiary);
    __initReentrancyGuard();
    __initERC20(
      string(abi.encodePacked(_name, " Eden Dao Reserve")),
      string(abi.encodePacked("edn-", _symbol)),
      ERC20(_asset).decimals()
    );
    __initERC4626(ERC20(_asset));
    __initComptrolled(_comptroller);

    performancePoints = 1000; // 10%
    emit UpdatePerformancePoints(performancePoints);

    lastReportTimestamp = uint64(block.timestamp);
    activationTimestamp = uint64(block.timestamp);
  }

  function _mint(address to, uint256 amount) internal override(ERC20, Note) {
    super._mint(to, amount);
  }

  function beforeWithdraw(uint256 assets, uint256) internal override {
    address reserve = address(this);
    for (
      uint256 i = 0;
      asset.balanceOf(reserve) < assets && i < MAX_STRATEGIES;
      i++
    ) {
      address vaultAddress = withdrawalQueue[i];
      ReserveVaultState memory s = vaults[vaultAddress];
      ERC4626 vault = ERC4626(vaultAddress);
      uint256 assetsToWithdraw = _min(
        assets,
        _min(s.totalDebt, vault.maxWithdraw(reserve))
      );
      vault.withdraw(assetsToWithdraw, reserve, reserve);
      assets -= assetsToWithdraw;
    }
  }

  function withdrawToken(address token, uint256 amount)
    external
    override
    requiresAuth
  {
    // Disable authority withdrawals of the underlying asset
    require(token != address(asset), "Reserve: INVALID_TOKEN");
    TransferToken(token).transfer(comptrollerAddress(), amount);
  }

  function totalShares() public view returns (uint256) {
    return previewDeposit(totalAssets());
  }

  function totalAssets() public view override returns (uint256) {
    return asset.balanceOf(address(this)) + totalDebt - lockedProfit;
  }

  function setDepositLimit(uint256 limit) external requiresAuth {
    depositLimit = limit;
    emit UpdateDepositLimit(depositLimit);
  }

  function setPerformancePoints(uint64 points) external requiresAuth {
    require(points <= 500 && points <= MAX_BPS / 2, "Reserve: INVALID_BP");
    performancePoints = points;
    emit UpdatePerformancePoints(performancePoints);
  }

  function setWithdrawalQueue(address[MAX_STRATEGIES] memory queue)
    external
    requiresAuth
  {
    address[SET_SIZE] memory set;
    for (uint256 i = 0; i < MAX_STRATEGIES; i++) {
      if (queue[i] == address(0)) {
        require(withdrawalQueue[i] == address(0), "Vault: UNAUTHORIZED");
        break;
      }

      require(withdrawalQueue[i] != address(0), "Vault: UNAUTHORIZED");
      require(
        vaults[queue[i]].activationTimestamp != 0,
        "Vault: INACTIVE_VAULT"
      );

      uint256 key = uint256(uint160(queue[i])) & (SET_SIZE - 1);
      for (uint256 j = 0; j < SET_SIZE; j++) {
        uint256 idx = (key + j) % SET_SIZE;
        require(set[idx] != queue[i], "Vault: DUPLICATE_VAULT");
        if (set[idx] == address(0)) {
          set[idx] = queue[i];
          break;
        }
      }

      withdrawalQueue[i] = queue[i];
    }

    emit UpdateWithdrawalQueue(queue);
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
    require(
      withdrawalQueue[MAX_STRATEGIES - 1] == address(0),
      "Reserve: QUEUE_LIMIT"
    );
    require(vault != address(0), "Reserve: INVALID_ADDRESS");
    require(
      address(asset) == address(ERC4626(vault).asset()),
      "Reserve: INVALID_ASSET"
    );
    require(vaults[vault].activationTimestamp == 0, "Reserve: ACTIVE_VAULT");
    initialState.lastReportTimestamp = uint64(block.timestamp);
    vaults[vault] = initialState;
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

  modifier onlyActiveVault(address vault) {
    require(vaults[vault].activationTimestamp != 0, "Reserve: INACTIVE_VAULT");
    _;
  }

  function setReserveVaultState(address vault, ReserveVaultState memory state)
    external
    requiresAuth
    onlyActiveVault(vault)
    onlyValidState(state)
  {
    ReserveVaultState storage s = vaults[vault];
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
    uint256 vaultDebt = vaults[vault].totalDebt;
    if (isPaused || debtPoints == 0) {
      return vaultDebt;
    }

    uint256 vaultDebtLimit = (vaults[vault].debtPoints * totalAssets()) /
      MAX_BPS;

    if (vaultDebt <= vaultDebtLimit) {
      return 0;
    }

    return vaultDebt - vaultDebtLimit;
  }

  function creditAvailable(address vault) public view returns (uint256) {
    if (isPaused) return 0;

    uint256 reserveDebtLimit = totalAssets().mulDivDown(debtPoints, MAX_BPS);
    uint256 vaultDebt = vaults[vault].totalDebt;
    uint256 vaultDebtLimit = totalAssets().mulDivDown(
      vaults[vault].debtPoints,
      MAX_BPS
    );

    if (vaultDebtLimit <= vaultDebt || reserveDebtLimit <= totalDebt) {
      return 0;
    }

    uint256 availableDebt = _min(
      asset.balanceOf(address(this)),
      _min(vaultDebtLimit - vaultDebt, reserveDebtLimit - totalDebt)
    );

    if (availableDebt < vaults[vault].minDebtPerHarvest) {
      return 0;
    }

    return _min(availableDebt, vaults[vault].maxDebtPerHarvest);
  }

  function expectedReturn(address vault) public view returns (uint256) {
    ReserveVaultState memory s = vaults[vault];
    uint256 timeSinceHarvest = block.timestamp - s.lastReportTimestamp;
    uint256 totalHarvestTime = s.lastReportTimestamp - s.activationTimestamp;

    if (timeSinceHarvest == 0 || totalHarvestTime == 0) {
      return 0;
    }

    return s.totalGain.mulDivDown(timeSinceHarvest, totalHarvestTime);
  }

  // solhint-disable-next-line code-complexity
  function report(
    uint256 gain,
    uint256 loss,
    uint256 debtPayment
  ) external onlyActiveVault(msg.sender) returns (uint256) {
    // When paused or when revoked vault should return all assets
    if (isPaused || vaults[msg.sender].debtPoints == 0) {
      return ERC4626(msg.sender).totalAssets();
    }

    require(
      asset.balanceOf(msg.sender) >= gain + debtPayment,
      "Reserve: INVALID_STATE"
    );
    ReserveVaultState storage s = vaults[msg.sender];

    if (loss > 0) {
      require(loss <= s.totalDebt, "Vault: INVALID_LOSS");

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
    uint256 credit = creditAvailable(msg.sender);
    uint256 outstandingDebt = debtOutstanding(msg.sender);
    debtPayment = _min(debtPayment, outstandingDebt);

    if (debtPayment > 0) {
      s.totalDebt -= debtPayment;
      totalDebt -= debtPayment;
      outstandingDebt -= debtPayment;
    }

    if (credit > 0) {
      s.totalDebt += credit;
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

    uint256 publicGoodGains;
    uint256 vaultegistGains;
    if (
      gain == 0 ||
      s.activationTimestamp == block.timestamp || // Only valid for active contracts
      s.lastReportTimestamp != block.timestamp // Only valid for this timestamp
    ) {
      publicGoodGains = 0;
      vaultegistGains = 0;
    } else {
      publicGoodGains = gain.mulDivDown(performancePoints, MAX_BPS);
      vaultegistGains = gain.mulDivDown(s.performancePoints, MAX_BPS);
    }

    uint256 performanceGains = publicGoodGains + vaultegistGains;
    if (performanceGains != 0) {
      uint256 reward = previewDeposit(performanceGains);
      uint256 vaultegistReward = vaultegistGains.mulDivDown(
        reward,
        performanceGains
      );
      uint256 publicGoodReward = reward - vaultegistReward;

      if (publicGoodReward > 0) {
        _mint(beneficiary, publicGoodReward);
      }
      if (vaultegistReward > 0) {
        _mint(msg.sender, vaultegistReward);
      }
    }

    uint256 lockedProfitBeforeLoss = lockedProfit + gain - performanceGains;

    lockedProfit = loss > lockedProfitBeforeLoss
      ? 0
      : lockedProfitBeforeLoss - loss;
    lastReportTimestamp = s.lastReportTimestamp = uint64(block.timestamp);

    emit ReserveVaultStateReport(
      msg.sender,
      s.debtPoints,
      gain,
      loss,
      debtPayment,
      s.totalGain,
      s.totalLoss,
      s.totalDebt,
      credit
    );

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
    emit UpdateWithdrawalQueue(withdrawalQueue);
  }

  function _max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? b : a;
  }
}
