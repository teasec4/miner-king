import 'dart:async';

import 'package:crypto_king/domain/catalogs/coin_catalog.dart';
import 'package:crypto_king/domain/catalogs/cooling_catalog.dart';
import 'package:crypto_king/domain/catalogs/course_catalog.dart';
import 'package:crypto_king/domain/catalogs/debuff_catalog.dart';
import 'package:crypto_king/domain/catalogs/gpu_catalog.dart';
import 'package:crypto_king/domain/catalogs/investment_catalog.dart';
import 'package:crypto_king/domain/catalogs/job_catalog.dart';
import 'package:crypto_king/domain/catalogs/loan_catalog.dart';
import 'package:crypto_king/domain/catalogs/office_catalog.dart';
import 'package:crypto_king/domain/catalogs/paste_catalog.dart';
import 'package:crypto_king/domain/catalogs/property_catalog.dart';
import 'package:crypto_king/domain/catalogs/psu_catalog.dart';
import 'package:crypto_king/domain/catalogs/slot_catalog.dart';
import 'package:crypto_king/domain/catalogs/solar_catalog.dart';
import 'package:crypto_king/domain/models/farm.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/game_event.dart';
import 'package:crypto_king/domain/models/gpu_instance.dart';
import 'package:crypto_king/domain/models/gpu_model.dart';
import 'package:crypto_king/domain/models/inventory_item.dart';
import 'package:crypto_king/domain/models/investment.dart';
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
  int _lastWatchdogTick = 0;
  int _nextBmRefresh = 0;
  int _bmGen = 0;
  GameEvent? lastEvent;

  /// Callback when a new event is triggered.
  void Function(GameEvent)? onEvent;

  GameState() : _game = _createInitialGame() {
    _startWatchdog();
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) {
      // Restart if timer died
      if (_tickTimer == null || !_tickTimer!.isActive) {
        startTicks();
        return;
      }
      // Also check tick is actually advancing (not stuck)
      final currentTick = _game.tick;
      if (_lastWatchdogTick > 0 && currentTick == _lastWatchdogTick) {
        // Ticker stalled — force restart
        _tickTimer?.cancel();
        startTicks();
      }
      _lastWatchdogTick = currentTick;
    });
  }

  Game get game => _game;

  static Game _createInitialGame() {
    final gpu = GpuInstance(
      id: _uuid.v4(),
      modelId: GpuCatalog.gtx1060.id,
      miningCoinId: 'btc',
      condition: 0.5, // starts half-broken
    );

    final loan = Loan(
      id: 'small',
      name: 'Quick Loan',
      principal: LoanCatalog.small.principal,
      interestPerMinute: LoanCatalog.small.interestPerMinute,
    )..remaining = LoanCatalog.small.principal * 1.1;

    return Game(
      money: 500,
      holdings: {'btc': 0, 'eth': 0, 'sol': 0, 'doge': 0, 'pepe': 0, 'usdt': 0},
      coins: CoinCatalog.initialCoins(),
      electricityRate: 0.25,
      farm: Farm(gpuList: [gpu], totalSlots: 1, coolingSystem: 'basic'),
      activeJobId: 'food_l1',
      activeLoans: [loan],
    );
  }

  void setCharacter(CharacterType c) {
    switch (c) {
      case CharacterType.miner:
        // +25% hashrate, GPU 100%, no loan — pure mining start
        _game = _game.copyWith(
          money: 300,
          activeLoans: [], // no debt
          farm: _game.farm.copyWith(
            gpuList: [_game.farm.gpuList.first.copyWith(condition: 1.0)],
          ),
          character: c,
        );
        break;
      case CharacterType.engineer:
        // -50% wear, -30% repair, GPU 100%, small loan
        _game = _game.copyWith(
          money: 500,
          farm: _game.farm.copyWith(
            gpuList: [_game.farm.gpuList.first.copyWith(condition: 1.0)],
          ),
          character: c,
        );
        break;
      case CharacterType.businessman:
        // +$500 cash, -15% shop, small loan
        _game = _game.copyWith(
          money: 1000,
          electricityRate: 0.25 * 0.85,
          character: c,
        );
        break;
      case CharacterType.hustler:
        {
          // +100% job EXP, medium loan ($2200 debt)
          final medLoan = Loan(
            id: 'medium',
            name: 'Business Loan',
            principal: LoanCatalog.medium.principal,
            interestPerMinute: LoanCatalog.medium.interestPerMinute,
          )..remaining = LoanCatalog.medium.principal * 1.1;
          _game = _game.copyWith(
            money: 600,
            activeLoans: [medLoan],
            character: c,
          );
          break;
        }
      case CharacterType.student:
        {
          final largeLoan = Loan(
            id: 'large',
            name: 'Expansion Loan',
            principal: LoanCatalog.large.principal,
            interestPerMinute: LoanCatalog.large.interestPerMinute,
          )..remaining = LoanCatalog.large.principal * 1.1;
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
    notifyListeners();
  }

  void startTicks({Duration interval = const Duration(seconds: 1)}) {
    if (_tickTimer?.isActive == true) return; // already running
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(interval, (_) {
      _safeTick();
    });
  }

  void _safeTick() {
    try {
      _maybeRefreshPool();
      // Black Market global timer
      if (_nextBmRefresh == 0) _nextBmRefresh = _game.tick + 300;
      if (_game.tick >= _nextBmRefresh) {
        _bmGen++;
        _nextBmRefresh = _game.tick + 300;
      }
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
    // GPU goes to inventory
    _addToInventory(
      'gpu',
      model.id,
      model.name,
      '${model.baseHashrate.toStringAsFixed(0)} MH/s, ${model.basePowerConsumption.toStringAsFixed(0)}W',
    );
    _game = _game.copyWith(money: _game.money - price);
    notifyListeners();
    return true;
  }

  bool buyBlackMarketGpu(GpuModel model, int price, List<String> debuffs) {
    if (_game.money < price) return false;
    // Black market GPU goes to inventory with debuff data
    _addToInventory(
      'gpu',
      model.id,
      model.name,
      '${model.baseHashrate.toStringAsFixed(0)} MH/s, ${model.basePowerConsumption.toStringAsFixed(0)}W',
      data: {'debuffs': debuffs},
    );
    _game = _game.copyWith(money: _game.money - price);
    notifyListeners();
    return true;
  }

  /// Install a GPU from inventory into the rig.
  bool installGpu(String inventoryItemId) {
    final invIdx = _game.inventory.indexWhere((i) => i.id == inventoryItemId);
    if (invIdx == -1) return false;
    final item = _game.inventory[invIdx];
    if (item.type != 'gpu') return false;

    final model = GpuCatalog.byId(item.itemId);
    if (model == null) return false;

    // Check motherboard can handle this GPU tier
    if (!SlotCatalog.canInstallGpu(_game.farm.totalSlots, model.id)) {
      return false;
    }

    final debuffs =
        (item.data?['debuffs'] as List?)?.cast<String>() ?? <String>[];

    final instance = GpuInstance(
      id: _uuid.v4(),
      modelId: model.id,
      miningCoinId: 'btc',
      temperature: model.baseTemperature,
      debuffs: debuffs,
    );

    final newInventory = [..._game.inventory];
    newInventory.removeAt(invIdx);

    _game = _game.copyWith(
      inventory: newInventory,
      farm: _game.farm.copyWith(gpuList: [..._game.farm.gpuList, instance]),
    );
    notifyListeners();
    return true;
  }

  void _addToInventory(
    String type,
    String itemId,
    String name,
    String detail, {
    Map<String, dynamic>? data,
  }) {
    final item = InventoryItem(
      id: _uuid.v4(),
      itemId: itemId,
      type: type,
      name: name,
      detail: detail,
      data: data,
    );
    _game = _game.copyWith(inventory: [..._game.inventory, item]);
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

  bool buySlotTier(SlotTier tier) {
    if (_game.money < tier.price) return false;
    _addToInventory(
      'motherboard',
      'mobo_${tier.slots}',
      'Motherboard ${tier.slots} slots',
      '${tier.slots} slots',
    );
    _game = _game.copyWith(money: _game.money - tier.price);
    notifyListeners();
    return true;
  }

  bool buyCooling(CoolingUpgrade upgrade) {
    if (_game.money < upgrade.price) return false;
    _addToInventory(
      'cooling',
      upgrade.id,
      upgrade.name,
      '${upgrade.tempReduction}°C',
    );
    _game = _game.copyWith(money: _game.money - upgrade.price);
    notifyListeners();
    return true;
  }

  bool buySolar(SolarUpgrade upgrade) {
    if (_game.money < upgrade.price) return false;
    _game = _game.copyWith(
      money: _game.money - upgrade.price,
      farm: _game.farm.copyWith(
        solarPower: _game.farm.solarPower + upgrade.powerGen,
      ),
    );
    notifyListeners();
    return true;
  }

  bool buyPsu(PsuUpgrade upgrade) {
    if (_game.money < upgrade.price) return false;
    _addToInventory(
      'psu',
      upgrade.id,
      upgrade.name,
      '${upgrade.maxWattPerGpu}W',
    );
    _game = _game.copyWith(money: _game.money - upgrade.price);
    notifyListeners();
    return true;
  }

  bool buyPaste(PasteUpgrade upgrade) {
    if (_game.money < upgrade.price) return false;
    _addToInventory(
      'paste',
      upgrade.id,
      upgrade.name,
      '${upgrade.tempReduction}°C',
    );
    _game = _game.copyWith(money: _game.money - upgrade.price);
    notifyListeners();
    return true;
  }

  /// Equip an inventory item to a GPU slot.
  bool equipToGpu(String inventoryItemId, String gpuId) {
    final invIdx = _game.inventory.indexWhere((i) => i.id == inventoryItemId);
    if (invIdx == -1) return false;
    final item = _game.inventory[invIdx];
    if (item.isEquipped) return false;

    final gpuIdx = _game.farm.gpuList.indexWhere((g) => g.id == gpuId);
    if (gpuIdx == -1) return false;
    final gpu = _game.farm.gpuList[gpuIdx];

    // Motherboard tier gates equipment level
    final moboTier = SlotCatalog.tiers.indexWhere(
      (t) => t.slots == _game.farm.totalSlots,
    );
    if (moboTier >= 0) {
      final itemTier = switch (item.type) {
        'cooling' => CoolingCatalog.indexOf(item.itemId),
        'psu' => PsuCatalog.indexOf(item.itemId),
        'paste' => PasteCatalog.indexOf(item.itemId),
        _ => 0,
      };
      if (itemTier > moboTier) return false;
    }

    final newGpu = switch (item.type) {
      'cooling' => gpu.copyWith(equippedCooling: item.itemId),
      'psu' => gpu.copyWith(equippedPsu: item.itemId),
      'paste' => gpu.copyWith(equippedPaste: item.itemId),
      'bios' => gpu.copyWith(equippedBios: item.itemId),
      _ => null,
    };
    if (newGpu == null) return false;

    final newInventory = [..._game.inventory];
    newInventory[invIdx] = item.copyWith(equippedToGpu: gpuId);
    final newGpus = [..._game.farm.gpuList];
    newGpus[gpuIdx] = newGpu;

    _game = _game.copyWith(
      inventory: newInventory,
      farm: _game.farm.copyWith(gpuList: newGpus),
    );
    notifyListeners();
    return true;
  }

  /// Unequip an item from a GPU back to inventory.
  bool unequipFromGpu(String gpuId, String type) {
    final gpuIdx = _game.farm.gpuList.indexWhere((g) => g.id == gpuId);
    if (gpuIdx == -1) return false;
    final gpu = _game.farm.gpuList[gpuIdx];

    final invIdx = _game.inventory.indexWhere(
      (i) => i.equippedToGpu == gpuId && i.type == type,
    );
    if (invIdx == -1) return false;

    final newGpu = switch (type) {
      'cooling' => gpu.copyWith(equippedCooling: null),
      'psu' => gpu.copyWith(equippedPsu: null),
      'paste' => gpu.copyWith(equippedPaste: null),
      'bios' => gpu.copyWith(equippedBios: null),
      _ => null,
    };
    if (newGpu == null) return false;

    final newInventory = [..._game.inventory];
    final oldItem = _game.inventory[invIdx];
    newInventory[invIdx] = InventoryItem(
      id: oldItem.id,
      itemId: oldItem.itemId,
      type: oldItem.type,
      name: oldItem.name,
      detail: oldItem.detail,
      equippedToGpu: null, // explicitly set to null
      data: oldItem.data,
    );
    final newGpus = [..._game.farm.gpuList];
    newGpus[gpuIdx] = newGpu;

    _game = _game.copyWith(
      inventory: newInventory,
      farm: _game.farm.copyWith(gpuList: newGpus),
    );
    notifyListeners();
    return true;
  }

  /// Use a motherboard item from inventory (adds slots).
  bool useMotherboard(String inventoryItemId) {
    final invIdx = _game.inventory.indexWhere((i) => i.id == inventoryItemId);
    if (invIdx == -1) return false;
    final item = _game.inventory[invIdx];
    if (item.type != 'motherboard') return false;

    final moboSlots = switch (item.itemId) {
      'mobo_2' => 2,
      'mobo_4' => 4,
      'mobo_8' => 8,
      'mobo_12' => 12,
      _ => 0,
    };
    if (moboSlots <= _game.farm.totalSlots) return false;

    final newInventory = [..._game.inventory];
    newInventory.removeAt(invIdx);

    _game = _game.copyWith(
      inventory: newInventory,
      farm: _game.farm.copyWith(totalSlots: moboSlots),
    );
    notifyListeners();
    return true;
  }

  // ── Equipment upgrade ──

  int equippedUpgradeCost(String gpuId, String type) {
    final gpu = _game.farm.gpuList.where((g) => g.id == gpuId).firstOrNull;
    if (gpu == null) return 0;
    final moboTier = SlotCatalog.tiers.indexWhere(
      (t) => t.slots == _game.farm.totalSlots,
    );
    if (moboTier < 0) return 0;
    switch (type) {
      case 'cooling':
        final currentId = gpu.equippedCooling ?? 'basic';
        final fromIdx = CoolingCatalog.indexOf(currentId);
        if (fromIdx >= moboTier) return 0;
        return CoolingCatalog.upgradeCost(fromIdx, fromIdx + 1);
      case 'psu':
        final currentId = gpu.equippedPsu ?? 'psu_stock';
        final fromIdx = PsuCatalog.indexOf(currentId);
        if (fromIdx >= moboTier) return 0;
        return PsuCatalog.upgradeCost(fromIdx, fromIdx + 1);
      case 'paste':
        final currentId = gpu.equippedPaste ?? 'paste_none';
        final fromIdx = PasteCatalog.indexOf(currentId);
        if (fromIdx >= moboTier) return 0;
        return PasteCatalog.upgradeCost(fromIdx, fromIdx + 1);
      case 'gpu':
        final fromIdx = GpuCatalog.indexOf(gpu.modelId);
        if (fromIdx >= moboTier) return 0;
        return GpuCatalog.upgradeCost(fromIdx, fromIdx + 1);
      default:
        return 0;
    }
  }

  String? equippedNextTier(String gpuId, String type) {
    final gpu = _game.farm.gpuList.where((g) => g.id == gpuId).firstOrNull;
    if (gpu == null) return null;
    switch (type) {
      case 'cooling':
        final currentId = gpu.equippedCooling ?? 'basic';
        final idx = CoolingCatalog.indexOf(currentId);
        return CoolingCatalog.all.length > idx + 1
            ? CoolingCatalog.all[idx + 1].name
            : null;
      case 'psu':
        final currentId = gpu.equippedPsu ?? 'psu_stock';
        final idx = PsuCatalog.indexOf(currentId);
        return PsuCatalog.all.length > idx + 1
            ? PsuCatalog.all[idx + 1].name
            : null;
      case 'paste':
        final currentId = gpu.equippedPaste ?? 'paste_none';
        final idx = PasteCatalog.indexOf(currentId);
        return PasteCatalog.all.length > idx + 1
            ? PasteCatalog.all[idx + 1].name
            : null;
      case 'gpu':
        final idx = GpuCatalog.indexOf(gpu.modelId);
        return GpuCatalog.all.length > idx + 1
            ? GpuCatalog.all[idx + 1].name
            : null;
      default:
        return null;
    }
  }

  bool upgradeEquipped(String gpuId, String type) {
    final cost = equippedUpgradeCost(gpuId, type);
    if (cost <= 0 || _game.money < cost) return false;
    final gpuIdx = _game.farm.gpuList.indexWhere((g) => g.id == gpuId);
    if (gpuIdx < 0) return false;
    final gpu = _game.farm.gpuList[gpuIdx];

    final newGpus = [..._game.farm.gpuList];

    switch (type) {
      case 'cooling':
        final currentId = gpu.equippedCooling ?? 'basic';
        final idx = CoolingCatalog.indexOf(currentId);
        final next = CoolingCatalog.all[idx + 1];
        // Remove old equipped item from inventory
        _removeEquippedFromInventory(gpuId, 'cooling');
        // Add new item to inventory as equipped
        _addEquippedToInventory(
          'cooling',
          next.id,
          next.name,
          '${next.tempReduction}°C',
          gpuId,
        );
        newGpus[gpuIdx] = gpu.copyWith(equippedCooling: next.id);
        break;
      case 'psu':
        final currentId = gpu.equippedPsu ?? 'psu_stock';
        final idx = PsuCatalog.indexOf(currentId);
        final next = PsuCatalog.all[idx + 1];
        _removeEquippedFromInventory(gpuId, 'psu');
        _addEquippedToInventory(
          'psu',
          next.id,
          next.name,
          '${next.maxWattPerGpu}W',
          gpuId,
        );
        newGpus[gpuIdx] = gpu.copyWith(equippedPsu: next.id);
        break;
      case 'paste':
        final currentId = gpu.equippedPaste ?? 'paste_none';
        final idx = PasteCatalog.indexOf(currentId);
        final next = PasteCatalog.all[idx + 1];
        _removeEquippedFromInventory(gpuId, 'paste');
        _addEquippedToInventory(
          'paste',
          next.id,
          next.name,
          '${next.tempReduction}°C',
          gpuId,
        );
        newGpus[gpuIdx] = gpu.copyWith(equippedPaste: next.id);
        break;
      case 'gpu':
        final idx = GpuCatalog.indexOf(gpu.modelId);
        final next = GpuCatalog.all[idx + 1];
        newGpus[gpuIdx] = gpu.copyWith(
          modelId: next.id,
          temperature: next.baseTemperature,
        );
        break;
      default:
        return false;
    }

    _game = _game.copyWith(
      money: _game.money - cost,
      farm: _game.farm.copyWith(gpuList: newGpus),
    );
    notifyListeners();
    return true;
  }

  void _removeEquippedFromInventory(String gpuId, String type) {
    final idx = _game.inventory.indexWhere(
      (i) => i.equippedToGpu == gpuId && i.type == type,
    );
    if (idx >= 0) {
      final newInv = [..._game.inventory];
      newInv.removeAt(idx);
      _game = _game.copyWith(inventory: newInv);
    }
  }

  InventoryItem _addEquippedToInventory(
    String type,
    String itemId,
    String name,
    String detail,
    String gpuId,
  ) {
    final item = InventoryItem(
      id: _uuid.v4(),
      itemId: itemId,
      type: type,
      name: name,
      detail: detail,
      equippedToGpu: gpuId,
    );
    _game = _game.copyWith(inventory: [..._game.inventory, item]);
    return item;
  }

  // ── Jobs ──

  void startJob(String jobId) {
    _game = _game.copyWith(activeJobId: jobId);
    notifyListeners();
  }

  /// Start working in a career path at current level.
  void startPath(List<Job> path, int level) {
    final title = JobCatalog.titleForPath(path, level);
    if (title != null) startJob(title.id);
  }

  void quitJob() {
    // copyWith can't clear optional fields (null gets swallowed by ??)
    _game = Game(
      money: _game.money,
      holdings: _game.holdings,
      coins: _game.coins,
      electricityRate: _game.electricityRate,
      farm: _game.farm,
      activeModifiers: _game.activeModifiers,
      activeEvents: _game.activeEvents,
      activeLoans: _game.activeLoans,
      activeInvestments: _game.activeInvestments,
      properties: _game.properties,
      marketMood: _game.marketMood,
      loanRepayments: _game.loanRepayments,
      activeJobId: null,
      jobExperience: _game.jobExperience,
      completedCourses: _game.completedCourses,
      activeCourseId: _game.activeCourseId,
      courseTicksLeft: _game.courseTicksLeft,
      employees: _game.employees,
      officeId: _game.officeId,
      unseenEvents: _game.unseenEvents,
      employeePool: _game.employeePool,
      nextPoolRefresh: _game.nextPoolRefresh,
      character: _game.character,
      perks: _game.perks,
      tick: _game.tick,
    );
    notifyListeners();
  }

  // ── Education ──

  bool enrollCourse(String courseId) {
    final course = CourseCatalog.byId(courseId);
    if (course == null) return false;
    // Student: -30% course cost
    final price = _game.character == CharacterType.student
        ? (course.price * 0.7).ceil()
        : course.price;
    if (_game.money < price) return false;
    if (_game.activeCourseId != null) return false;
    if (_game.completedCourses.contains(courseId)) return false;
    for (final req in course.requiresCourse) {
      if (!_game.completedCourses.contains(req)) return false;
    }
    _game = _game.copyWith(
      money: _game.money - price,
      activeCourseId: courseId,
      courseTicksLeft: course.durationTicks,
    );
    notifyListeners();
    return true;
  }

  // ── Office ──

  bool buyOffice(String officeId) {
    // Sequential upgrade only: must be exactly the next tier
    final next = OfficeCatalog.nextTier(_game.officeId);
    if (next == null || next.id != officeId) return false;
    if (_game.money < next.price) return false;
    _game = _game.copyWith(money: _game.money - next.price, officeId: officeId);
    notifyListeners();
    return true;
  }

  /// Refresh the pool of available employees (3-4 random).
  void refreshEmployeePool() {
    final all = EmployeeCatalog.all.map((e) => e.id).toList();
    all.shuffle();
    _game = _game.copyWith(
      employeePool: all.take(all.length > 4 ? 4 : all.length).toList(),
      nextPoolRefresh: _game.tick + 300,
    );
    notifyListeners();
  }

  /// Check and auto-refresh expired pool.
  void _maybeRefreshPool() {
    if (_game.employeePool.isEmpty || _game.tick >= _game.nextPoolRefresh) {
      refreshEmployeePool();
    }
  }

  bool hireEmployee(String empId) {
    final office = _game.officeId != null
        ? OfficeCatalog.byId(_game.officeId!)
        : null;
    if (office == null) return false;
    if (_game.employees.length >= office.slots) return false;
    // Each employee type is unique (can only hire one of each)
    if (_game.employees.contains(empId)) return false;
    _game = _game.copyWith(employees: [..._game.employees, empId]);
    notifyListeners();
    return true;
  }

  void fireEmployee(String empId) {
    _game = _game.copyWith(
      employees: _game.employees.where((e) => e != empId).toList(),
    );
    notifyListeners();
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

  // ── Investments ──

  bool invest(String investId, double amount) {
    final template = InvestmentCatalog.byId(investId);
    if (template == null) return false;
    if (amount < template.minAmount) return false;
    if (_game.money < amount) return false;
    final inv = ActiveInvestment(
      investId: investId,
      amount: amount,
      ticksLeft: template.durationTicks,
    );
    _game = _game.copyWith(
      money: _game.money - amount,
      activeInvestments: [..._game.activeInvestments, inv],
    );
    notifyListeners();
    return true;
  }

  bool buyProperty(String propertyId) {
    final p = PropertyCatalog.byId(propertyId);
    if (p == null) return false;
    if (_game.money < p.price) return false;
    if (_game.properties.contains(propertyId)) return false;
    _game = _game.copyWith(
      money: _game.money - p.price,
      properties: [..._game.properties, propertyId],
    );
    notifyListeners();
    return true;
  }

  // ── Events ──

  int get blackMarketRefreshIn {
    if (_nextBmRefresh == 0) _nextBmRefresh = _game.tick + 300;
    return (_nextBmRefresh - _game.tick).clamp(0, 9999);
  }

  int get blackMarketGen => _bmGen;

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

  // ── Character & Perks ──

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
    var cost = (model.price * 0.30 * damage).ceil();
    // Engineer: -30% repair cost
    if (_game.character == CharacterType.engineer) cost = (cost * 0.7).ceil();
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

  /// Remove a specific debuff from a GPU for its repair cost.
  bool repairDebuff(String instanceId, String debuffId) {
    final index = _game.farm.gpuList.indexWhere((g) => g.id == instanceId);
    if (index == -1) return false;
    final gpu = _game.farm.gpuList[index];
    if (!gpu.debuffs.contains(debuffId)) return false;
    final debuff = DebuffCatalog.byId(debuffId);
    if (debuff == null) return false;
    var cost = debuff.repairCost;
    if (_game.character == CharacterType.engineer) cost = (cost * 0.7).ceil();
    if (_game.money < cost) return false;

    final newList = [..._game.farm.gpuList];
    newList[index] = gpu.copyWith(
      debuffs: gpu.debuffs.where((d) => d != debuffId).toList(),
    );
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
