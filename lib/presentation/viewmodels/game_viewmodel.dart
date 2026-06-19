import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/coin_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/domain/systems/credit_system.dart';
import 'package:crypto_king/domain/systems/electricity_system.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';
import 'package:crypto_king/domain/systems/thermal_system.dart';

class GameViewModel {
  final GameState _state;

  GameViewModel(this._state);

  Game get _game => _state.game;

  // ── Display getters ──

  double get money => _game.money;
  double get electricityRate => _game.electricityRate;
  int get tick => _game.tick;
  int get totalSlots => _game.farm.totalSlots;
  int get usedSlots => _game.farm.usedSlots;

  double get totalHashrate => MiningSystem.totalHashrate(_game);
  double get totalPowerDraw => ElectricitySystem.totalPowerDraw(_game);
  double get electricityCostPerHour => ElectricitySystem.costPerHour(_game);

  double get netProfitPerHour {
    final coin = _game.primaryCoin;
    final mined = MiningSystem.mine(_game)[coin.id] ?? 0;
    return mined * 3600 * coin.price - electricityCostPerHour;
  }

  /// Holding amount for a coin.
  double holding(String coinId) => _game.holdings[coinId] ?? 0;

  /// All coin states.
  List<CoinState> get coins => _game.coins;

  /// Coin display info.
  CoinState? coinState(String id) => _game.coin(id);

  double holdingValue(String coinId) {
    final c = _game.coin(coinId);
    return (c?.price ?? 0) * holding(coinId);
  }

  double get totalHoldingsValue {
    return _game.coins.fold(0, (sum, c) => sum + holdingValue(c.id));
  }

  List<GameEvent> get activeEvents => _game.activeEvents;
  List<Loan> get activeLoans => _game.activeLoans;
  double get totalDebt => CreditSystem.totalDebt(_game);

  bool canSellCoin(String coinId) => holding(coinId) > 0;

  // ── GPU list ──

  List<GpuDisplayInfo> get gpus {
    return _game.farm.gpuList.map((gpu) {
      final model = GpuCatalog.byId(gpu.modelId);
      final coin = CoinCatalog.byId(gpu.miningCoinId);
      return GpuDisplayInfo(
        instanceId: gpu.id,
        modelName: model?.name ?? 'Unknown',
        modelId: gpu.modelId,
        miningCoinId: gpu.miningCoinId,
        miningCoinName: coin?.name ?? 'BTC',
        isPowered: gpu.isPowered,
        temperature: gpu.temperature,
        condition: gpu.condition,
        overclockLevel: gpu.overclockLevel,
        isDead: gpu.condition <= 0,
        tempStatus: ThermalSystem.status(gpu.temperature),
      );
    }).toList();
  }

  bool canUpgrade(String instanceId) {
    final gpu = _game.farm.gpuList.where((g) => g.id == instanceId).firstOrNull;
    if (gpu == null) return false;
    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return false;
    final idx = GpuCatalog.all.indexOf(model);
    if (idx >= GpuCatalog.all.length - 1) return false;
    return _game.money >= (GpuCatalog.all[idx + 1].price - model.price);
  }

  int upgradeCost(String instanceId) {
    final gpu = _game.farm.gpuList.where((g) => g.id == instanceId).firstOrNull;
    if (gpu == null) return 0;
    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return 0;
    final idx = GpuCatalog.all.indexOf(model);
    if (idx >= GpuCatalog.all.length - 1) return 0;
    return GpuCatalog.all[idx + 1].price - model.price;
  }

  int repairCost(String instanceId) {
    final gpu = _game.farm.gpuList.where((g) => g.id == instanceId).firstOrNull;
    if (gpu == null || gpu.condition >= 1.0) return 0;
    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return 0;
    return (model.price * 0.1 * (1.0 - gpu.condition)).round();
  }

  bool canRepair(String instanceId) {
    final cost = repairCost(instanceId);
    return cost > 0 && _game.money >= cost;
  }

  // ── Slots ──

  int? get nextSlotTier => SlotCatalog.nextTier(_game.farm.totalSlots)?.slots;
  int get nextSlotCost =>
      SlotCatalog.nextTier(_game.farm.totalSlots)?.price ?? 0;
  bool get canBuySlot => nextSlotTier != null && _game.money >= nextSlotCost;

  // ── Shop ──

  List<ShopGpuEntry> get shopGpus {
    return GpuCatalog.all.map((model) {
      return ShopGpuEntry(
        model: model,
        canAfford: _game.money >= model.price,
        hasSlots: _game.farm.hasFreeSlots,
        canBuy: _game.money >= model.price && _game.farm.hasFreeSlots,
      );
    }).toList();
  }

  // ── Actions ──

  void sellCoin(String id) => _state.sellCoin(id);
  void sellAllCoins() => _state.sellAllCoins();
  bool swapCoins(String from, String to, double amount) =>
      _state.swapCoins(from, to, amount);
  bool takeLoan(String id) => _state.takeLoan(id);
  bool repayLoan(String id, double amount) => _state.repayLoan(id, amount);
  void startTicks() => _state.startTicks();
  bool upgradeGpu(String id) => _state.upgradeGpu(id);
  void toggleOverclock(String id) => _state.toggleOverclock(id);
  bool repairGpu(String id) => _state.repairGpu(id);
  bool buyGpu(GpuModel model) => _state.buyGpu(model);
  bool buySlot() => _state.buySlot();
  void setMiningCoin(String gpuId, String coinId) =>
      _state.setMiningCoin(gpuId, coinId);
  void togglePower(String gpuId) => _state.togglePower(gpuId);
}

class ShopGpuEntry {
  final GpuModel model;
  final bool canAfford;
  final bool hasSlots;
  final bool canBuy;

  const ShopGpuEntry({
    required this.model,
    required this.canAfford,
    required this.hasSlots,
    required this.canBuy,
  });
}

class GpuDisplayInfo {
  final String instanceId;
  final String modelName;
  final String modelId;
  final String miningCoinId;
  final String miningCoinName;
  final bool isPowered;
  final double temperature;
  final double condition;
  final int overclockLevel;
  final bool isDead;
  final String tempStatus;

  const GpuDisplayInfo({
    required this.instanceId,
    required this.modelName,
    required this.modelId,
    required this.miningCoinId,
    required this.miningCoinName,
    required this.isPowered,
    required this.temperature,
    required this.condition,
    required this.overclockLevel,
    required this.isDead,
    required this.tempStatus,
  });
}
