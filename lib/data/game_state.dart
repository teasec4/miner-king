import 'dart:async';

import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/models/farm.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/gpu_instance.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/systems/economy_system.dart';
import 'package:crypto_king/domain/systems/tick_system.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Holds the [Game] aggregate and drives the simulation via a periodic timer.
class GameState extends ChangeNotifier {
  static final _uuid = const Uuid();

  Game _game;
  Timer? _tickTimer;

  GameState() : _game = _createInitialGame();

  Game get game => _game;

  // ── Initial state ──

  static Game _createInitialGame() {
    final gpu = GpuInstance(id: _uuid.v4(), modelId: GpuCatalog.gtx1060.id);

    return Game(
      money: 1000,
      coins: 0,
      coinPrice: 10.0,
      electricityRate: 0.12,
      farm: Farm(gpuList: [gpu], totalSlots: 1, coolingSystem: 'basic'),
    );
  }

  // ── Tick loop ──

  void startTicks({Duration interval = const Duration(seconds: 1)}) {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(interval, (_) {
      _game = TickSystem.tick(_game);
      notifyListeners();
    });
  }

  // ── Economy ──

  void sellAllCoins() {
    _game = EconomySystem.sellAllCoins(_game);
    notifyListeners();
  }

  void sellCoins(double amount) {
    _game = EconomySystem.sellCoins(_game, amount);
    notifyListeners();
  }

  bool buyGpu(GpuModel model) {
    if (_game.money < model.price) return false;
    if (!_game.farm.hasFreeSlots) return false;

    final instance = GpuInstance(
      id: _uuid.v4(),
      modelId: model.id,
      temperature: model.baseTemperature,
    );

    _game = _game.copyWith(
      money: _game.money - model.price,
      farm: _game.farm.copyWith(gpuList: [..._game.farm.gpuList, instance]),
    );
    notifyListeners();
    return true;
  }

  bool upgradeGpu(String instanceId) {
    final index = _game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return false;

    final gpu = _game.farm.gpuList[index];
    final currentModel = GpuCatalog.byId(gpu.modelId);
    if (currentModel == null) return false;

    final currentIdx = GpuCatalog.all.indexOf(currentModel);
    if (currentIdx >= GpuCatalog.all.length - 1) return false;

    final nextModel = GpuCatalog.all[currentIdx + 1];
    final cost = nextModel.price - currentModel.price;
    if (_game.money < cost) return false;

    final upgradedGpu = GpuInstance(
      id: instanceId,
      modelId: nextModel.id,
      condition: gpu.condition,
      temperature: nextModel.baseTemperature,
      overclockLevel: gpu.overclockLevel,
    );

    final newList = [..._game.farm.gpuList];
    newList[index] = upgradedGpu;

    _game = _game.copyWith(
      money: _game.money - cost,
      farm: _game.farm.copyWith(gpuList: newList),
    );
    notifyListeners();
    return true;
  }

  // ── Slots ──

  /// Buy the next slot tier (motherboard upgrade).
  bool buySlot() {
    final next = SlotCatalog.nextTier(_game.farm.totalSlots);
    if (next == null) return false;
    if (_game.money < next.price) return false;

    _game = _game.copyWith(
      money: _game.money - next.price,
      farm: _game.farm.copyWith(totalSlots: next.slots),
    );
    notifyListeners();
    return true;
  }

  // ── Overclock ──

  void toggleOverclock(String instanceId) {
    final index = _game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return;

    final gpu = _game.farm.gpuList[index];
    if (gpu.condition <= 0) return; // dead card

    final newLevel = gpu.overclockLevel > 0 ? 0 : 1;

    final newList = [..._game.farm.gpuList];
    newList[index] = gpu.copyWith(overclockLevel: newLevel);

    _game = _game.copyWith(farm: _game.farm.copyWith(gpuList: newList));
    notifyListeners();
  }

  // ── Repair ──

  /// Repair a GPU. Cost is proportional to damage.
  /// Full repair cost = 30% of model price.
  /// Restores condition to 1.0.
  bool repairGpu(String instanceId) {
    final index = _game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return false;

    final gpu = _game.farm.gpuList[index];
    if (gpu.condition >= 1.0) return false; // nothing to repair

    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return false;

    // Cost proportional to damage: 30% of model price * damage
    final damage = 1.0 - gpu.condition;
    final cost = (model.price * 0.3 * damage).round();
    if (_game.money < cost) return false;

    final newList = [..._game.farm.gpuList];
    newList[index] = gpu.copyWith(condition: 1.0);

    _game = _game.copyWith(
      money: _game.money - cost,
      farm: _game.farm.copyWith(gpuList: newList),
    );
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
