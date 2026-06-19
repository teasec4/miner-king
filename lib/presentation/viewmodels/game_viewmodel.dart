import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/systems/electricity_system.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';
import 'package:crypto_king/domain/systems/thermal_system.dart';

/// Thin ViewModel – reads from [GameState], exposes display-friendly getters.
class GameViewModel {
  final GameState _state;

  GameViewModel(this._state);

  Game get _game => _state.game;

  // ── Display getters ──

  double get money => _game.money;
  double get coins => _game.coins;
  double get coinPrice => _game.coinPrice;
  MarketPhase get marketPhase => _game.marketPhase;
  String get marketLabel => MarketSystem.phaseLabel(_game.marketPhase);
  String get marketIcon => MarketSystem.phaseIcon(_game.marketPhase);
  double get electricityRate => _game.electricityRate;
  int get tick => _game.tick;
  int get totalSlots => _game.farm.totalSlots;
  int get usedSlots => _game.farm.usedSlots;

  double get totalHashrate => MiningSystem.totalHashrate(_game);
  double get coinsPerSecond => MiningSystem.mine(_game);
  double get totalPowerDraw => ElectricitySystem.totalPowerDraw(_game);
  double get electricityCostPerHour => ElectricitySystem.costPerHour(_game);

  /// Net profit per hour: mining revenue − electricity cost.
  double get netProfitPerHour {
    final revenue = coinsPerSecond * 3600 * coinPrice;
    final cost = electricityCostPerHour;
    return revenue - cost;
  }

  List<GpuDisplayInfo> get gpus {
    return _game.farm.gpuList.map((gpu) {
      final model = GpuCatalog.byId(gpu.modelId);
      return GpuDisplayInfo(
        instanceId: gpu.id,
        modelName: model?.name ?? 'Unknown',
        modelId: gpu.modelId,
        temperature: gpu.temperature,
        condition: gpu.condition,
        overclockLevel: gpu.overclockLevel,
        isDead: gpu.condition <= 0,
        tempStatus: ThermalSystem.status(gpu.temperature),
      );
    }).toList();
  }

  List<GpuModel> get availableUpgrades {
    if (_game.farm.gpuList.isEmpty) return GpuCatalog.all;
    final current = GpuCatalog.byId(_game.farm.gpuList.first.modelId);
    if (current == null) return GpuCatalog.all;
    final idx = GpuCatalog.all.indexOf(current);
    if (idx < GpuCatalog.all.length - 1) {
      return [GpuCatalog.all[idx + 1]];
    }
    return [];
  }

  bool canUpgrade(String instanceId) {
    final gpu = _game.farm.gpuList.where((g) => g.id == instanceId).firstOrNull;
    if (gpu == null) return false;
    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return false;
    final idx = GpuCatalog.all.indexOf(model);
    if (idx >= GpuCatalog.all.length - 1) return false;
    final next = GpuCatalog.all[idx + 1];
    return _game.money >= (next.price - model.price);
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

  /// Repair cost: 30% of model price × damage ratio.
  int repairCost(String instanceId) {
    final gpu = _game.farm.gpuList.where((g) => g.id == instanceId).firstOrNull;
    if (gpu == null || gpu.condition >= 1.0) return 0;
    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return 0;
    final damage = 1.0 - gpu.condition;
    return (model.price * 0.3 * damage).round();
  }

  bool canRepair(String instanceId) {
    final cost = repairCost(instanceId);
    return cost > 0 && _game.money >= cost;
  }

  bool get canSellCoins => _game.coins > 0;

  // ── Slots ──

  int? get nextSlotTier => SlotCatalog.nextTier(_game.farm.totalSlots)?.slots;
  int get nextSlotCost =>
      SlotCatalog.nextTier(_game.farm.totalSlots)?.price ?? 0;
  bool get canBuySlot => nextSlotTier != null && _game.money >= nextSlotCost;

  // ── Shop ──

  /// All GPU models available for purchase.
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

  void sellAllCoins() => _state.sellAllCoins();
  void startTicks() => _state.startTicks();
  bool upgradeGpu(String id) => _state.upgradeGpu(id);
  void toggleOverclock(String id) => _state.toggleOverclock(id);
  bool repairGpu(String id) => _state.repairGpu(id);
  bool buyGpu(GpuModel model) => _state.buyGpu(model);
  bool buySlot() => _state.buySlot();
}

/// Shop display entry for a GPU model.
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

/// Lightweight display info for a GPU.
class GpuDisplayInfo {
  final String instanceId;
  final String modelName;
  final String modelId;
  final double temperature;
  final double condition;
  final int overclockLevel;
  final bool isDead;
  final String tempStatus; // 'normal', 'warning', 'critical'

  const GpuDisplayInfo({
    required this.instanceId,
    required this.modelName,
    required this.modelId,
    required this.temperature,
    required this.condition,
    required this.overclockLevel,
    required this.isDead,
    required this.tempStatus,
  });
}
