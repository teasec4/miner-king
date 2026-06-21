import 'dart:async';

import 'package:crypto_king/domain/catalogs/coin_catalog.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/job_catalog.dart';
import 'package:crypto_king/domain/catalogs/loan_catalog.dart';
import 'package:crypto_king/domain/catalogs/paste_catalog.dart';
import 'package:crypto_king/domain/catalogs/psu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/catalogs/solar_catalog.dart';
import 'package:crypto_king/domain/commands/economy_commands.dart';
import 'package:crypto_king/domain/commands/farm_commands.dart';
import 'package:crypto_king/domain/commands/gpu_commands.dart';
import 'package:crypto_king/domain/commands/life_commands.dart';
import 'package:crypto_king/domain/config/game_config.dart';
import 'package:crypto_king/domain/models/farm.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/events/game_events.dart';
import 'package:crypto_king/domain/models/gpu_instance.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/domain/models/player_profile.dart';
import 'package:crypto_king/domain/systems/systems.dart';
import 'package:crypto_king/domain/systems/tick_system.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class GameState extends ChangeNotifier {
  static final _uuid = const Uuid();

  final Systems _systems;
  late final TickSystem _tickSystem;

  Game _game;
  Timer? _tickTimer;
  Timer? _watchdog;
  int _lastWatchdogTick = 0;
  int _nextBmRefresh = 0;
  int _bmGen = 0;
  GameEvent? lastEvent;

  /// Callback when a new event is triggered.
  void Function(GameEvent)? onEvent;

  GameState({Systems? systems})
    : _systems = systems ?? Systems(),
      _game = _createInitialGame() {
    _tickSystem = TickSystem(_systems);
  }
  // Watchdog + tick timer start in setCharacter(), not here.
  // Game must not tick until the player picks a character.

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(
      Duration(seconds: GameConfig.watchdogIntervalSeconds),
      (_) {
        if (_tickTimer == null || !_tickTimer!.isActive) {
          startTicks();
          return;
        }
        final currentTick = _game.tick;
        if (_lastWatchdogTick > 0 && currentTick == _lastWatchdogTick) {
          _tickTimer?.cancel();
          startTicks();
        }
        _lastWatchdogTick = currentTick;
      },
    );
  }

  // ── Accessors ──

  Game get game => _game;

  int get blackMarketRefreshIn {
    if (_nextBmRefresh == 0) {
      _nextBmRefresh = _game.tick + GameConfig.blackMarketRefreshTicks;
    }
    return (_nextBmRefresh - _game.tick).clamp(0, 9999);
  }

  int get blackMarketGen => _bmGen;

  // ── Init ──

  static Game _createInitialGame() {
    final gpu = GpuInstance(
      id: _uuid.v4(),
      modelId: GpuCatalog.gtx1060.id,
      miningCoinId: 'btc',
      condition: 0.5,
    );

    final loan =
        Loan(
            id: 'small',
            name: 'Quick Loan',
            principal: LoanCatalog.small.principal,
            interestPerMinute: LoanCatalog.small.interestPerMinute,
          )
          ..remaining =
              LoanCatalog.small.principal * (1 + GameConfig.loanOriginationFee);

    return Game(
      money: 500,
      holdings: {'btc': 0, 'eth': 0, 'sol': 0, 'doge': 0, 'pepe': 0, 'usdt': 0},
      coins: CoinCatalog.initialCoins(),
      electricityRate: GameConfig.defaultElectricityRate,
      farm: Farm(gpuList: [gpu], totalSlots: 1, coolingSystem: 'basic'),
      activeJobId: 'food_l1',
      activeLoans: [loan],
    );
  }

  void setCharacter(CharacterType c) {
    switch (c) {
      case CharacterType.miner:
        _game = _game.copyWith(
          money: 300,
          activeLoans: [],
          farm: _game.farm.copyWith(
            gpuList: [_game.farm.gpuList.first.copyWith(condition: 1.0)],
          ),
          character: c,
        );
        break;
      case CharacterType.engineer:
        _game = _game.copyWith(
          money: 500,
          farm: _game.farm.copyWith(
            gpuList: [_game.farm.gpuList.first.copyWith(condition: 1.0)],
          ),
          character: c,
        );
        break;
      case CharacterType.businessman:
        _game = _game.copyWith(
          money: 1000,
          electricityRate:
              GameConfig.defaultElectricityRate *
              GameConfig.businessmanShopDiscount,
          character: c,
        );
        break;
      case CharacterType.hustler:
        {
          final medLoan =
              Loan(
                  id: 'medium',
                  name: 'Business Loan',
                  principal: LoanCatalog.medium.principal,
                  interestPerMinute: LoanCatalog.medium.interestPerMinute,
                )
                ..remaining =
                    LoanCatalog.medium.principal *
                    (1 + GameConfig.loanOriginationFee);
          _game = _game.copyWith(
            money: 600,
            activeLoans: [medLoan],
            character: c,
          );
          break;
        }
      case CharacterType.student:
        {
          final largeLoan =
              Loan(
                  id: 'large',
                  name: 'Expansion Loan',
                  principal: LoanCatalog.large.principal,
                  interestPerMinute: LoanCatalog.large.interestPerMinute,
                )
                ..remaining =
                    LoanCatalog.large.principal *
                    (1 + GameConfig.loanOriginationFee);
          _game = _game.copyWith(
            money: 800,
            completedCourses: ['basic_it'],
            activeLoans: [largeLoan],
            character: c,
          );
          break;
        }
      case CharacterType.debug:
        _game = _game.copyWith(
          money: 100000,
          completedCourses: [
            'basic_it',
            'management',
            'data_analytics',
            'marketing',
            'programming',
            'business',
          ],
          activeLoans: [],
          farm: _game.farm.copyWith(
            gpuList: [_game.farm.gpuList.first.copyWith(condition: 1.0)],
          ),
          character: c,
        );
        break;
    }
    _startWatchdog();
    notifyListeners();
  }

  // ── Timer ──

  void startTicks({
    Duration interval = const Duration(seconds: GameConfig.tickIntervalSeconds),
  }) {
    if (_tickTimer?.isActive == true) return;
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(interval, (_) {
      _safeTick();
    });
  }

  void _safeTick() {
    try {
      _maybeRefreshPool();
      if (_nextBmRefresh == 0) {
        _nextBmRefresh = _game.tick + GameConfig.blackMarketRefreshTicks;
      }
      if (_game.tick >= _nextBmRefresh) {
        _bmGen++;
        _nextBmRefresh = _game.tick + GameConfig.blackMarketRefreshTicks;
      }
      final (newGame, event) = _tickSystem.tick(_game);
      _game = newGame;
      if (event != null) {
        lastEvent = event;
        onEvent?.call(event);
      }
      notifyListeners();
    } catch (_) {
      _tickTimer?.cancel();
      _tickTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _safeTick(),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Economy actions (delegated to EconomyCommands)
  // ═══════════════════════════════════════════════════════════════

  void sellCoin(String coinId) {
    _game = EconomyCommands.sellCoin(_game, coinId);
    notifyListeners();
  }

  void sellAllCoins() {
    _game = EconomyCommands.sellAllCoins(_game);
    notifyListeners();
  }

  bool buyCoinWithCash(String coinId, double cashAmount) {
    final result = EconomyCommands.buyCoinWithCash(_game, coinId, cashAmount);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool sellCoinForCash(String coinId, double coinAmount) {
    final result = EconomyCommands.sellCoinForCash(_game, coinId, coinAmount);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool swapCoins(String fromId, String toId, double amount) {
    final result = EconomyCommands.swapCoins(_game, fromId, toId, amount);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool takeLoan(String loanId) {
    final (newGame, ok) = EconomyCommands.takeLoan(_game, loanId);
    if (!ok) return false;
    _game = newGame;
    notifyListeners();
    return true;
  }

  bool repayLoan(String loanId, double amount) {
    final (newGame, ok) = EconomyCommands.repayLoan(_game, loanId, amount);
    if (!ok) return false;
    _game = newGame;
    notifyListeners();
    return true;
  }

  bool invest(String investId, double amount) {
    final (newGame, ok) = EconomyCommands.invest(_game, investId, amount);
    if (!ok) return false;
    _game = newGame;
    notifyListeners();
    return true;
  }

  bool buyProperty(String propertyId) {
    final (newGame, ok) = EconomyCommands.buyProperty(_game, propertyId);
    if (!ok) return false;
    _game = newGame;
    notifyListeners();
    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  // GPU actions (delegated to GpuCommands)
  // ═══════════════════════════════════════════════════════════════

  bool buyGpu(GpuModel model) {
    final (newGame, item) = GpuCommands.buyGpu(_game, model);
    if (item.id.isEmpty) return false;
    _game = newGame.copyWith(inventory: [...newGame.inventory, item]);
    notifyListeners();
    return true;
  }

  bool buyBlackMarketGpu(GpuModel model, int price, List<String> debuffs) {
    final (newGame, item) = GpuCommands.buyBlackMarketGpu(
      _game,
      model,
      price,
      debuffs,
    );
    if (item.id.isEmpty) return false;
    _game = newGame.copyWith(inventory: [...newGame.inventory, item]);
    notifyListeners();
    return true;
  }

  bool installGpu(String inventoryItemId) {
    final result = GpuCommands.installGpu(_game, inventoryItemId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool upgradeGpu(String instanceId) {
    final result = GpuCommands.upgradeGpu(_game, instanceId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool repairGpu(String instanceId) {
    final result = GpuCommands.repairGpu(_game, instanceId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool repairDebuff(String instanceId, String debuffId) {
    final result = GpuCommands.repairDebuff(_game, instanceId, debuffId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  void toggleOverclock(String instanceId) {
    final result = GpuCommands.toggleOverclock(_game, instanceId);
    if (result == null) return;
    _game = result;
    notifyListeners();
  }

  void togglePower(String instanceId) {
    final result = GpuCommands.togglePower(_game, instanceId);
    if (result == null) return;
    _game = result;
    notifyListeners();
  }

  void setMiningCoin(String instanceId, String coinId) {
    final result = GpuCommands.setMiningCoin(_game, instanceId, coinId);
    if (result == null) return;
    _game = result;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Farm actions (delegated to FarmCommands)
  // ═══════════════════════════════════════════════════════════════

  bool buySlotTier(SlotTier tier) {
    final result = FarmCommands.buySlotTier(_game, tier);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool buyCooling(CoolingUpgrade upgrade) {
    final result = FarmCommands.buyCooling(_game, upgrade);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool buySolar(SolarUpgrade upgrade) {
    final result = FarmCommands.buySolar(_game, upgrade);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool buyPsu(PsuUpgrade upgrade) {
    final result = FarmCommands.buyPsu(_game, upgrade);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool buyPaste(PasteUpgrade upgrade) {
    final result = FarmCommands.buyPaste(_game, upgrade);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool equipToGpu(String inventoryItemId, String gpuId) {
    final result = FarmCommands.equipToGpu(_game, inventoryItemId, gpuId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool unequipFromGpu(String gpuId, String type) {
    final result = FarmCommands.unequipFromGpu(_game, gpuId, type);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool useMotherboard(String inventoryItemId) {
    final result = FarmCommands.useMotherboard(_game, inventoryItemId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  int equippedUpgradeCost(String gpuId, String type) {
    return FarmCommands.upgradeCost(_game, gpuId, type);
  }

  String? equippedNextTier(String gpuId, String type) {
    return FarmCommands.nextTierName(_game, gpuId, type);
  }

  bool upgradeEquipped(String gpuId, String type) {
    final result = FarmCommands.upgradeEquipped(_game, gpuId, type);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  // Life actions (delegated to LifeCommands)
  // ═══════════════════════════════════════════════════════════════

  void startJob(String jobId) {
    _game = LifeCommands.startJob(_game, jobId);
    notifyListeners();
  }

  void startPath(List<Job> path, int level) {
    final title = JobCatalog.titleForPath(path, level);
    if (title != null) startJob(title.id);
  }

  void quitJob() {
    _game = LifeCommands.quitJob(_game);
    notifyListeners();
  }

  bool enrollCourse(String courseId) {
    final result = LifeCommands.enrollCourse(_game, courseId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  bool buyOffice(String officeId) {
    final result = LifeCommands.buyOffice(_game, officeId);
    if (result == null) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  void refreshEmployeePool() {
    _game = LifeCommands.refreshEmployeePool(_game);
    notifyListeners();
  }

  void _maybeRefreshPool() {
    if (_game.employeePool.isEmpty || _game.tick >= _game.nextPoolRefresh) {
      refreshEmployeePool();
    }
  }

  bool hireEmployee(String empId) {
    final result = LifeCommands.hireEmployee(_game, empId);
    if (identical(result, _game)) return false;
    _game = result;
    notifyListeners();
    return true;
  }

  void fireEmployee(String empId) {
    _game = LifeCommands.fireEmployee(_game, empId);
    notifyListeners();
  }

  void addPerk(Perk perk) {
    final result = LifeCommands.addPerk(_game, perk);
    if (result == null) return;
    _game = result;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Misc
  // ═══════════════════════════════════════════════════════════════

  void resetBlackMarketTimer() {
    _nextBmRefresh = 0;
    notifyListeners();
  }

  void clearUnseen(String category) {
    final unseen = Map<String, int>.from(_game.unseenEvents);
    unseen[category] = 0;
    _game = _game.copyWith(unseenEvents: unseen);
    notifyListeners();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }
}
