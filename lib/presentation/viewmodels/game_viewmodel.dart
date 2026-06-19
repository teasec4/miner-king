import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/coin_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/solar_catalog.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/models/gpu_instance.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/domain/models/player_profile.dart';
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
  double get solarPower => ElectricitySystem.solarPower(_game);
  String get coolingSystem => _game.farm.coolingSystem;
  String get coolingLabel => switch (_game.farm.coolingSystem) {
    'fans' => 'Fan Cooling',
    'water' => 'Water Cooling',
    'immersion' => 'Immersion',
    _ => '',
  };
  double get electricityCostPerHour => ElectricitySystem.costPerHour(_game);

  double get netProfitPerHour {
    final mined = MiningSystem.mine(_game);
    double revenue = 0;
    for (final entry in mined.entries) {
      final coin = _game.coin(entry.key);
      if (coin != null) {
        revenue += entry.value * 3600 * coin.price;
      }
    }
    return revenue - electricityCostPerHour;
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
  double get marketMood => _game.marketMood;
  List<Loan> get activeLoans => _game.activeLoans;
  Map<String, int> get loanRepayments => _game.loanRepayments;
  double get totalDebt => CreditSystem.totalDebt(_game);

  bool isLoanUnlocked(String loanId) {
    final tiers = ['small', 'medium', 'large'];
    final idx = tiers.indexOf(loanId);
    if (idx <= 0) return true;
    return (_game.loanRepayments[tiers[idx - 1]] ?? 0) >= 2;
  }

  bool canSellCoin(String coinId) => holding(coinId) > 0;

  // ── GPU list ──

  List<GpuDisplayInfo> get gpus {
    return _game.farm.gpuList.map((gpu) {
      final model = GpuCatalog.byId(gpu.modelId);
      final coin = CoinCatalog.byId(gpu.miningCoinId);
      final hashrate = _gpuHashrate(gpu, model);
      final revenuePerHour =
          hashrate *
          0.0002 *
          (coin?.baseReward ?? 1) *
          3600 *
          (coin?.price ?? 0);
      return GpuDisplayInfo(
        instanceId: gpu.id,
        modelName: model?.name ?? 'Unknown',
        modelId: gpu.modelId,
        miningCoinId: gpu.miningCoinId,
        miningCoinName: coin?.name ?? 'BTC',
        isPowered: gpu.isPowered,
        revenuePerHour: revenuePerHour,
        temperature: gpu.temperature,
        condition: gpu.condition,
        overclockLevel: gpu.overclockLevel,
        siliconLotteryLevel: gpu.siliconLotteryLevel,
        isDead: gpu.condition <= 0,
        tempStatus: ThermalSystem.status(gpu.temperature),
      );
    }).toList();
  }

  double _gpuHashrate(GpuInstance gpu, GpuModel? model) {
    if (gpu.condition <= 0 || !gpu.isPowered || model == null) return 0;
    double base = model.baseHashrate;
    if (gpu.effectiveOverclock > 0) base *= 1 + 0.2 * gpu.effectiveOverclock;
    if (_game.perks.any((p) => p.effect == PerkEffect.siliconLottery)) {
      base *= 1.1;
    }
    if (_game.perks.any((p) => p.effect == PerkEffect.riskLover)) {
      base *= 1.5;
    }
    return base * gpu.condition;
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
    final cost = (model.price * 0.1 * (1.0 - gpu.condition)).ceil();
    return cost;
  }

  bool canRepair(String instanceId) {
    final gpu = _game.farm.gpuList.where((g) => g.id == instanceId).firstOrNull;
    if (gpu == null || gpu.condition >= 1.0) return false;
    return _game.money >= repairCost(instanceId);
  }

  // ── Slots ──

  int? get nextSlotTier => SlotCatalog.nextTier(_game.farm.totalSlots)?.slots;
  int get nextSlotCost =>
      SlotCatalog.nextTier(_game.farm.totalSlots)?.price ?? 0;
  bool get canBuySlot => nextSlotTier != null && _game.money >= nextSlotCost;

  bool get hasGpuSale => _game.activeEvents.any((e) => e.id == 'gpu_sale');

  // ── Shop ──

  List<ShopGpuEntry> get shopGpus {
    final sale = hasGpuSale;
    return GpuCatalog.all.map((model) {
      final price = sale ? (model.price * 0.7).ceil() : model.price;
      return ShopGpuEntry(
        model: model,
        effectivePrice: price,
        canAfford: _game.money >= price,
        hasSlots: _game.farm.hasFreeSlots,
        canBuy: _game.money >= price && _game.farm.hasFreeSlots,
      );
    }).toList();
  }

  // ── Actions ──

  void sellCoin(String id) => _state.sellCoin(id);
  void sellAllCoins() => _state.sellAllCoins();
  bool buyCoinWithCash(String id, double cash) =>
      _state.buyCoinWithCash(id, cash);
  bool sellCoinForCash(String id, double amount) =>
      _state.sellCoinForCash(id, amount);
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
  bool buyCooling(CoolingUpgrade u) => _state.buyCooling(u);
  bool buySolar(SolarUpgrade u) => _state.buySolar(u);
  void setMiningCoin(String gpuId, String coinId) =>
      _state.setMiningCoin(gpuId, coinId);
  void togglePower(String gpuId) => _state.togglePower(gpuId);
}

class ShopGpuEntry {
  final GpuModel model;
  final int effectivePrice;
  final bool canAfford;
  final bool hasSlots;
  final bool canBuy;

  const ShopGpuEntry({
    required this.model,
    required this.effectivePrice,
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
  final double revenuePerHour;
  final double temperature;
  final double condition;
  final int overclockLevel;
  final int siliconLotteryLevel;
  final bool isDead;
  final String tempStatus;

  const GpuDisplayInfo({
    required this.instanceId,
    required this.modelName,
    required this.modelId,
    required this.miningCoinId,
    required this.miningCoinName,
    required this.isPowered,
    required this.revenuePerHour,
    required this.temperature,
    required this.condition,
    required this.overclockLevel,
    required this.siliconLotteryLevel,
    required this.isDead,
    required this.tempStatus,
  });
}
