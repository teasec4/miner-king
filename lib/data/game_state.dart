import 'dart:async';

import 'package:crypto_king/domain/catalogs/coin_catalog.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/loan_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/catalogs/solar_catalog.dart';
import 'package:crypto_king/domain/models/farm.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/domain/models/gpu_instance.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/domain/models/player_profile.dart';
import 'package:crypto_king/domain/systems/economy_system.dart';
import 'package:crypto_king/domain/systems/tick_system.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class GameState extends ChangeNotifier {
  static final _uuid = const Uuid();

  Game _game;
  Timer? _tickTimer;
  Timer? _watchdog;
  GameEvent? lastEvent;

  /// Callback when a new event is triggered.
  void Function(GameEvent)? onEvent;

  GameState() : _game = _createInitialGame() {
    _startWatchdog();
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_tickTimer == null || !_tickTimer!.isActive) {
        startTicks();
      }
    });
  }

  Game get game => _game;

  static Game _createInitialGame() {
    final gpu = GpuInstance(
      id: _uuid.v4(),
      modelId: GpuCatalog.gtx1060.id,
      miningCoinId: 'btc',
    );

    return Game(
      money: 1000,
      holdings: {'btc': 0, 'eth': 0, 'sol': 0, 'doge': 0, 'pepe': 0, 'usdt': 0},
      coins: CoinCatalog.initialCoins(),
      electricityRate: 0.12,
      farm: Farm(gpuList: [gpu], totalSlots: 1, coolingSystem: 'basic'),
    );
  }

  void startTicks({Duration interval = const Duration(seconds: 1)}) {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(interval, (_) {
      _safeTick();
    });
  }

  void _safeTick() {
    try {
      final (newGame, event) = TickSystem.tick(_game);
      _game = newGame;
      if (event != null) {
        lastEvent = event;
        onEvent?.call(event);
      }
      notifyListeners();
    } catch (_) {
      // Tick crashed (e.g. callback on dead widget) – restart timer
      _tickTimer?.cancel();
      _tickTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _safeTick(),
      );
    }
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

  bool buyCoinWithCash(String coinId, double cashAmount) {
    final result = EconomySystem.buyCoinWithCash(_game, coinId, cashAmount);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool sellCoinForCash(String coinId, double coinAmount) {
    final result = EconomySystem.sellCoinForCash(_game, coinId, coinAmount);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool swapCoins(String fromId, String toId, double amount) {
    final result = EconomySystem.swapCoins(_game, fromId, toId, amount);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool buyGpu(GpuModel model) {
    final hasSale = _game.activeEvents.any((e) => e.id == 'gpu_sale');
    final price = hasSale ? (model.price * 0.7).ceil() : model.price;
    if (_game.money < price) return false;
    if (!_game.farm.hasFreeSlots) return false;

    final instance = GpuInstance(
      id: _uuid.v4(),
      modelId: model.id,
      miningCoinId: 'btc', // default to BTC
      temperature: model.baseTemperature,
    );

    _game = _game.copyWith(
      money: _game.money - price,
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

  bool buyCooling(CoolingUpgrade upgrade) {
    if (_game.money < upgrade.price) return false;
    if (_game.farm.coolingSystem == upgrade.id) return false;
    _game = _game.copyWith(
      money: _game.money - upgrade.price,
      farm: _game.farm.copyWith(coolingSystem: upgrade.id),
    );
    notifyListeners();
    return true;
  }

  bool buySolar(SolarUpgrade upgrade) {
    if (_game.money < upgrade.price) return false;
    // Solar panels stack (additive)
    _game = _game.copyWith(
      money: _game.money - upgrade.price,
      farm: _game.farm.copyWith(
        solarPower: _game.farm.solarPower + upgrade.powerGen,
      ),
    );
    notifyListeners();
    return true;
  }

  // ── Bank ──

  bool takeLoan(String loanId) {
    final template = LoanCatalog.byId(loanId);
    if (template == null) return false;
    // Already have this loan?
    if (_game.activeLoans.any((l) => l.id == loanId)) return false;

    // Credit history: need 2x repayments of previous tier
    final tiers = ['small', 'medium', 'large'];
    final idx = tiers.indexOf(loanId);
    if (idx > 0) {
      final prevRepayments = _game.loanRepayments[tiers[idx - 1]] ?? 0;
      if (prevRepayments < 2) return false;
    }

    final loan = Loan(
      id: template.id,
      name: template.name,
      principal: template.principal,
      interestPerMinute: template.interestPerMinute,
    )..remaining = template.principal * 1.1; // 10% fee upfront
    _game = _game.copyWith(
      money: _game.money + loan.principal,
      activeLoans: [..._game.activeLoans, loan],
    );
    notifyListeners();
    return true;
  }

  bool repayLoan(String loanId, double amount) {
    final index = _game.activeLoans.indexWhere((l) => l.id == loanId);
    if (index == -1) return false;
    final loan = _game.activeLoans[index];
    final toPay = amount.clamp(0, loan.remaining);
    if (_game.money < toPay) return false;

    final newLoans = [..._game.activeLoans];
    final newRemaining = loan.remaining - toPay;
    if (newRemaining <= 0.01) {
      // Paid off — increment repayment counter
      final reps = Map<String, int>.from(_game.loanRepayments);
      reps[loanId] = (reps[loanId] ?? 0) + 1;
      newLoans.removeAt(index);
      _game = _game.copyWith(
        money: _game.money - toPay,
        activeLoans: newLoans,
        loanRepayments: reps,
      );
    } else {
      newLoans[index] = loan.copyWith(remaining: newRemaining);
      _game = _game.copyWith(money: _game.money - toPay, activeLoans: newLoans);
    }
    notifyListeners();
    return true;
  }

  // ── Character & Perks ──

  void setCharacter(CharacterType c) {
    _game = _game.copyWith(character: c);
    notifyListeners();
  }

  void addPerk(Perk perk) {
    if (_game.perks.any((p) => p.id == perk.id)) return;
    // Apply perk effects
    _game = _applyPerkEffect(_game, perk);
    _game = _game.copyWith(perks: [..._game.perks, perk]);
    notifyListeners();
  }

  static Game _applyPerkEffect(Game game, Perk perk) {
    switch (perk.effect) {
      case PerkEffect.betterMobo:
        return game.copyWith(
          farm: game.farm.copyWith(totalSlots: game.farm.totalSlots + 2),
        );
      case PerkEffect.cheapElectricity:
        return game.copyWith(electricityRate: game.electricityRate * 0.8);
      default:
        return game; // applied dynamically in systems
    }
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

  // ── Power toggle ──

  void togglePower(String instanceId) {
    final index = _game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return;
    final gpu = _game.farm.gpuList[index];
    if (gpu.condition <= 0) return; // dead card can't toggle
    final newList = [..._game.farm.gpuList];
    newList[index] = gpu.copyWith(isPowered: !gpu.isPowered);
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
    final cost = (model.price * 0.1 * damage).ceil();
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
    _watchdog?.cancel();
    super.dispose();
  }
}
