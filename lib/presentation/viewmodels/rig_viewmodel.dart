import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/psu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/catalogs/solar_catalog.dart';
import 'package:crypto_king/domain/catalogs/debuff_catalog.dart';
import 'package:crypto_king/domain/config/game_config.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/models/player_profile.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';
import 'package:crypto_king/domain/systems/electricity_system.dart';
import 'package:crypto_king/domain/systems/thermal_system.dart';
import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/presentation/notifiers/notifiers.dart';

/// ViewModel for the Rig tab: GPU list, hashrate, temps, equipment.
class RigViewModel {
  final RigNotifier _n;
  RigViewModel(this._n);
  Game get game => _n.game;
  GameState get state => _n.state;

  double get totalHashrate => MiningSystem.totalHashrate(game);
  double get totalPowerDraw => ElectricitySystem.totalPowerDraw(game);
  double get solarPower => ElectricitySystem.solarPower(game);
  String get coolingSystem => game.farm.coolingSystem;
  String get coolingLabel => switch (game.farm.coolingSystem) {
    'fans' => 'Fan Cooling',
    'water' => 'Water Cooling',
    'immersion' => 'Immersion',
    _ => '',
  };
  String get psuTier => game.farm.psuTier;
  int get psuMaxWatt => PsuCatalog.byId(game.farm.psuTier)?.maxTotalWatt ?? 150;
  String get psuLabel => switch (game.farm.psuTier) {
    'psu_bronze' => 'Bronze PSU',
    'psu_gold' => 'Gold PSU',
    'psu_platinum' => 'Platinum PSU',
    _ => 'Stock PSU',
  };
  int get psuCapacity => PsuCatalog.capacity(game.farm.psuTier);
  int get totalSlots => game.farm.totalSlots;
  int get usedSlots => game.farm.usedSlots;
  bool get farmHasFreeSlots => game.farm.hasFreeSlots;
  int? get nextSlotTier => SlotCatalog.nextTier(game.farm.totalSlots)?.slots;
  int get nextSlotCost =>
      SlotCatalog.nextTier(game.farm.totalSlots)?.price ?? 0;
  bool get canBuySlot => nextSlotTier != null && game.money >= nextSlotCost;

  List<GpuDisplayInfo> get gpus {
    return game.farm.gpuList.map((gpu) {
      final model = GpuCatalog.byId(gpu.modelId);
      final coin = game.coin(gpu.miningCoinId);
      final c = gpu.cycleProgress;
      final rw = GameConfig.rewardPerCycle * (coin?.baseReward ?? 1);
      return GpuDisplayInfo(
        instanceId: gpu.id,
        modelName: model?.name ?? 'Unknown',
        modelId: gpu.modelId,
        miningCoinId: gpu.miningCoinId,
        miningCoinName: coin?.name ?? 'BTC',
        isPowered: gpu.isPowered,
        revenuePerHour: MiningSystem.revenuePerHour(gpu, game),
        revenuePerMin: MiningSystem.revenuePerMin(gpu, game),
        temperature: gpu.temperature,
        condition: gpu.condition,
        overclockLevel: gpu.overclockLevel,
        siliconLotteryLevel: gpu.siliconLotteryLevel,
        isDead: gpu.condition <= 0,
        tempStatus: ThermalSystem.status(gpu.temperature),
        cycleProgress: c,
        cycleReward: rw,
        revenuePerCycle: rw * (coin?.price ?? 0),
        debuffs: gpu.debuffs,
      );
    }).toList();
  }

  bool canUpgrade(String id) {
    final gpu = game.farm.gpuList.where((g) => g.id == id).firstOrNull;
    if (gpu == null) return false;
    final m = GpuCatalog.byId(gpu.modelId);
    if (m == null) return false;
    final idx = GpuCatalog.all.indexOf(m);
    return idx < GpuCatalog.all.length - 1 &&
        game.money >= (GpuCatalog.all[idx + 1].price - m.price);
  }

  int upgradeCost(String id) {
    final gpu = game.farm.gpuList.where((g) => g.id == id).firstOrNull;
    if (gpu == null) return 0;
    final m = GpuCatalog.byId(gpu.modelId);
    if (m == null) return 0;
    final idx = GpuCatalog.all.indexOf(m);
    return idx < GpuCatalog.all.length - 1
        ? GpuCatalog.all[idx + 1].price - m.price
        : 0;
  }

  int repairCost(String id) {
    final gpu = game.farm.gpuList.where((g) => g.id == id).firstOrNull;
    if (gpu == null || gpu.condition >= 1.0) return 0;
    final m = GpuCatalog.byId(gpu.modelId);
    if (m == null) return 0;
    return (m.price * GameConfig.repairCostFraction * (1.0 - gpu.condition))
        .ceil();
  }

  bool canRepair(String id) {
    final gpu = game.farm.gpuList.where((g) => g.id == id).firstOrNull;
    return gpu != null && gpu.condition < 1.0 && game.money >= repairCost(id);
  }

  int debuffRepairCost(String debuffId) {
    final d = DebuffCatalog.byId(debuffId);
    if (d == null) return 0;
    var cost = d.repairCost;
    if (game.character == CharacterType.engineer)
      cost = (cost * GameConfig.engineerRepairDiscount).ceil();
    return cost;
  }

  bool get hasGpuSale => game.activeEvents.any((e) => e.id == 'gpu_sale');
  List<ShopGpuEntry> get shopGpus {
    final sale = hasGpuSale;
    return GpuCatalog.all.map((m) {
      final p = sale ? (m.price * GameConfig.gpuSaleDiscount).ceil() : m.price;
      return ShopGpuEntry(
        model: m,
        effectivePrice: p,
        canBuy: game.money >= p && game.farm.hasFreeSlots,
      );
    }).toList();
  }

  bool buyGpu(GpuModel m) => state.buyGpu(m);
  bool buyBlackMarketGpu(GpuModel m, int p, List<String> d) =>
      state.buyBlackMarketGpu(m, p, d);
  bool upgradeGpu(String id) => state.upgradeGpu(id);
  void toggleOverclock(String id) => state.toggleOverclock(id);
  bool repairGpu(String id) => state.repairGpu(id);
  bool repairDebuff(String g, String d) => state.repairDebuff(g, d);
  bool buySlotTier(SlotTier t) => state.buySlotTier(t);
  bool buyCooling(CoolingUpgrade u) => state.buyCooling(u);
  bool buySolar(SolarUpgrade u) => state.buySolar(u);
  bool buyPsu(PsuUpgrade u) => state.buyPsu(u);
  int get coolingUpgradeCost => state.coolingUpgradeCost();
  String? get nextCoolingName => state.nextCoolingName();
  int get psuUpgradeCost => state.psuUpgradeCost();
  String? get nextPsuName => state.nextPsuName();
  void setMiningCoin(String g, String c) => state.setMiningCoin(g, c);
  bool rerollSiliconLottery(String g) => state.rerollSiliconLottery(g);
  void togglePower(String g) => state.togglePower(g);
}

// ── Display types ──

class GpuDisplayInfo {
  final String instanceId, modelName, modelId, miningCoinId, miningCoinName;
  final bool isPowered;
  final double revenuePerHour, revenuePerMin, temperature, condition;
  final int overclockLevel, siliconLotteryLevel;
  final bool isDead;
  final String tempStatus;
  final double cycleProgress, cycleReward, revenuePerCycle;
  final List<String> debuffs;
  const GpuDisplayInfo({
    required this.instanceId,
    required this.modelName,
    required this.modelId,
    required this.miningCoinId,
    required this.miningCoinName,
    required this.isPowered,
    required this.revenuePerHour,
    required this.revenuePerMin,
    required this.temperature,
    required this.condition,
    required this.overclockLevel,
    required this.siliconLotteryLevel,
    required this.isDead,
    required this.tempStatus,
    required this.cycleProgress,
    required this.cycleReward,
    required this.revenuePerCycle,
    required this.debuffs,
  });
}

class ShopGpuEntry {
  final GpuModel model;
  final int effectivePrice;
  final bool canBuy;
  const ShopGpuEntry({
    required this.model,
    required this.effectivePrice,
    required this.canBuy,
  });
}
