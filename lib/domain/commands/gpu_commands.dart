import 'package:uuid/uuid.dart';
import '../config/game_config.dart';
import '../catalogs/debuff_catalog.dart';
import '../catalogs/gpu_catalog.dart';
import '../models/game.dart';
import '../models/gpu_instance.dart';
import '../models/gpu_model.dart';
import '../models/player_profile.dart';

final _gpuUuid = const Uuid();

/// Pure functions for GPU operations: buy, upgrade, repair, toggle.
/// GPUs are installed directly to the first free slot — no inventory.
class GpuCommands {
  GpuCommands._();

  // ── Buy (installs directly to slot) ──

  static Game? buyGpu(Game game, GpuModel model) {
    final hasSale = game.activeEvents.any((e) => e.id == 'gpu_sale');
    var price = hasSale
        ? (model.price * GameConfig.gpuSaleDiscount).ceil()
        : model.price;
    price = GameConfig.applyShopDiscount(price, game.shopMultiplier);
    if (game.money < price) return null;
    if (!game.farm.hasFreeSlots) return null;

    final instance = GpuInstance(
      id: _gpuUuid.v4(),
      modelId: model.id,
      miningCoinId: 'btc',
      temperature: model.baseTemperature,
    );
    return game.copyWith(
      money: game.money - price,
      farm: game.farm.copyWith(gpuList: [...game.farm.gpuList, instance]),
    );
  }

  static Game? buyBlackMarketGpu(
    Game game,
    GpuModel model,
    int price,
    List<String> debuffs,
  ) {
    price = GameConfig.applyShopDiscount(price, game.shopMultiplier);
    if (game.money < price) return null;
    if (!game.farm.hasFreeSlots) return null;

    final instance = GpuInstance(
      id: _gpuUuid.v4(),
      modelId: model.id,
      miningCoinId: 'btc',
      temperature: model.baseTemperature,
      debuffs: debuffs,
    );
    return game.copyWith(
      money: game.money - price,
      farm: game.farm.copyWith(gpuList: [...game.farm.gpuList, instance]),
    );
  }

  // ── Upgrade ──

  static Game? upgradeGpu(Game game, String instanceId) {
    final index = game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return null;

    final gpu = game.farm.gpuList[index];
    final currentModel = GpuCatalog.byId(gpu.modelId);
    if (currentModel == null) return null;

    final currentIdx = GpuCatalog.all.indexOf(currentModel);
    if (currentIdx >= GpuCatalog.all.length - 1) return null;

    final nextModel = GpuCatalog.all[currentIdx + 1];
    final cost = GameConfig.applyShopDiscount(
      nextModel.price - currentModel.price,
      game.shopMultiplier,
    );
    if (game.money < cost) return null;

    final newList = [...game.farm.gpuList];
    newList[index] = gpu.copyWith(modelId: nextModel.id);

    return game.copyWith(
      money: game.money - cost,
      farm: game.farm.copyWith(gpuList: newList),
    );
  }

  // ── Repair ──

  static Game? repairGpu(Game game, String instanceId) {
    final index = game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return null;
    final gpu = game.farm.gpuList[index];
    if (gpu.condition >= 1.0) return null;
    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return null;
    final damage = 1.0 - gpu.condition;
    var cost = (model.price * GameConfig.repairCostFraction * damage).ceil();
    cost = GameConfig.applyShopDiscount(cost, game.shopMultiplier);
    if (game.character == CharacterType.engineer) {
      cost = (cost * GameConfig.engineerRepairDiscount).ceil();
    }
    if (game.money < cost) return null;

    final newList = [...game.farm.gpuList];
    newList[index] = gpu.copyWith(condition: 1.0);
    return game.copyWith(
      money: game.money - cost,
      farm: game.farm.copyWith(gpuList: newList),
    );
  }

  static Game? repairDebuff(Game game, String instanceId, String debuffId) {
    final index = game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return null;
    final gpu = game.farm.gpuList[index];
    if (!gpu.debuffs.contains(debuffId)) return null;
    final debuff = DebuffCatalog.byId(debuffId);
    if (debuff == null) return null;
    var cost = debuff.repairCost;
    cost = GameConfig.applyShopDiscount(cost, game.shopMultiplier);
    if (game.character == CharacterType.engineer) {
      cost = (cost * GameConfig.engineerRepairDiscount).ceil();
    }
    if (game.money < cost) return null;

    final newList = [...game.farm.gpuList];
    newList[index] = gpu.copyWith(
      debuffs: gpu.debuffs.where((d) => d != debuffId).toList(),
    );
    return game.copyWith(
      money: game.money - cost,
      farm: game.farm.copyWith(gpuList: newList),
    );
  }

  // ── Toggle ──

  static Game? toggleOverclock(Game game, String instanceId) {
    final index = game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return null;
    final gpu = game.farm.gpuList[index];
    if (gpu.condition <= 0) return null;
    final newLevel = gpu.overclockLevel >= GameConfig.maxOverclockLevel
        ? 0
        : gpu.overclockLevel + 1;
    final newList = [...game.farm.gpuList];
    newList[index] = gpu.copyWith(overclockLevel: newLevel);
    return game.copyWith(farm: game.farm.copyWith(gpuList: newList));
  }

  static Game? togglePower(Game game, String instanceId) {
    final index = game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return null;
    final gpu = game.farm.gpuList[index];
    if (gpu.condition <= 0) return null;
    final newList = [...game.farm.gpuList];
    newList[index] = gpu.copyWith(isPowered: !gpu.isPowered);
    return game.copyWith(farm: game.farm.copyWith(gpuList: newList));
  }

  static Game? setMiningCoin(Game game, String instanceId, String coinId) {
    final index = game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return null;
    final newList = [...game.farm.gpuList];
    newList[index] = newList[index].copyWith(miningCoinId: coinId);
    return game.copyWith(farm: game.farm.copyWith(gpuList: newList));
  }

  // ── Silicon Lottery Reroll ──

  /// Reroll silicon lottery level (0-10%). Costs a flat fee.
  static Game? rerollSiliconLottery(
    Game game,
    String instanceId,
    int cost,
    int newLevel,
  ) {
    final index = game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return null;
    if (game.money < cost) return null;
    final gpu = game.farm.gpuList[index];
    if (gpu.condition <= 0) return null;
    final newList = [...game.farm.gpuList];
    newList[index] = gpu.copyWith(siliconLotteryLevel: newLevel);
    return game.copyWith(
      money: game.money - cost,
      farm: game.farm.copyWith(gpuList: newList),
    );
  }
}
