import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';

/// Thin ViewModel – reads from [GameState], exposes display-friendly getters.
/// Does NOT contain business logic.
class GameViewModel {
  final GameState _state;

  GameViewModel(this._state);

  Game get _game => _state.game;

  // ── Display getters ──

  double get money => _game.money;
  double get coins => _game.coins;
  double get coinPrice => _game.coinPrice;
  int get tick => _game.tick;
  int get totalSlots => _game.farm.totalSlots;
  int get usedSlots => _game.farm.usedSlots;

  double get totalHashrate => MiningSystem.totalHashrate(_game);

  /// Coins mined per second (approximate for display).
  double get coinsPerSecond => MiningSystem.mine(_game);

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
        isBroken: gpu.isBroken,
      );
    }).toList();
  }

  /// All GPU models available for purchase (that are better than what's installed).
  List<GpuModel> get availableUpgrades {
    // In v0.1, upgrade replaces the single GPU with next tier
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

  bool get canSellCoins => _game.coins > 0;

  // ── Actions (delegate to GameState) ──

  void sellAllCoins() => _state.sellAllCoins();
  void startTicks() => _state.startTicks();
  bool upgradeGpu(String id) => _state.upgradeGpu(id);
}

/// Lightweight display info for a GPU – avoids exposing domain internals to UI.
class GpuDisplayInfo {
  final String instanceId;
  final String modelName;
  final String modelId;
  final double temperature;
  final double condition;
  final int overclockLevel;
  final bool isBroken;

  const GpuDisplayInfo({
    required this.instanceId,
    required this.modelName,
    required this.modelId,
    required this.temperature,
    required this.condition,
    required this.overclockLevel,
    required this.isBroken,
  });
}
