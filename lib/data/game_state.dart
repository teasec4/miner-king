import 'dart:async';

import 'package:crypto_king/domain/catalogs/coin_catalog.dart';
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

class GameState extends ChangeNotifier {
  static final _uuid = const Uuid();

  Game _game;
  Timer? _tickTimer;

  GameState() : _game = _createInitialGame();

  Game get game => _game;

  static Game _createInitialGame() {
    final gpu = GpuInstance(
      id: _uuid.v4(),
      modelId: GpuCatalog.gtx1060.id,
      miningCoinId: 'btc',
    );

    return Game(
      money: 1000,
      holdings: {'btc': 0, 'eth': 0, 'doge': 0},
      coins: CoinCatalog.initialCoins(),
      electricityRate: 0.12,
      farm: Farm(gpuList: [gpu], totalSlots: 1, coolingSystem: 'basic'),
    );
  }

  void startTicks({Duration interval = const Duration(seconds: 1)}) {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(interval, (_) {
      _game = TickSystem.tick(_game);
      notifyListeners();
    });
  }

  // ── Economy ──

  void sellCoin(String coinId) {
    _game = EconomySystem.sellCoin(_game, coinId);
    notifyListeners();
  }

  void sellAllCoins() {
    _game = EconomySystem.sellAllCoins(_game);
    notifyListeners();
  }

  bool buyGpu(GpuModel model) {
    if (_game.money < model.price) return false;
    if (!_game.farm.hasFreeSlots) return false;

    final instance = GpuInstance(
      id: _uuid.v4(),
      modelId: model.id,
      miningCoinId: 'btc', // default to BTC
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

    final upgradedGpu = gpu.copyWith(modelId: nextModel.id);

    final newList = [..._game.farm.gpuList];
    newList[index] = upgradedGpu;

    _game = _game.copyWith(
      money: _game.money - cost,
      farm: _game.farm.copyWith(gpuList: newList),
    );
    notifyListeners();
    return true;
  }

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
    if (gpu.condition <= 0) return;

    final newLevel = gpu.overclockLevel > 0 ? 0 : 1;
    final newList = [..._game.farm.gpuList];
    newList[index] = gpu.copyWith(overclockLevel: newLevel);
    _game = _game.copyWith(farm: _game.farm.copyWith(gpuList: newList));
    notifyListeners();
  }

  // ── Coin switching ──

  void setMiningCoin(String instanceId, String coinId) {
    final index = _game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return;
    final newList = [..._game.farm.gpuList];
    newList[index] = newList[index].copyWith(miningCoinId: coinId);
    _game = _game.copyWith(farm: _game.farm.copyWith(gpuList: newList));
    notifyListeners();
  }

  // ── Repair ──

  bool repairGpu(String instanceId) {
    final index = _game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return false;
    final gpu = _game.farm.gpuList[index];
    if (gpu.condition >= 1.0) return false;

    final model = GpuCatalog.byId(gpu.modelId);
    if (model == null) return false;

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
