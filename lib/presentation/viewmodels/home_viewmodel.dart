import 'dart:async';

import 'package:crypto_king/domain/entities/miner.dart';
import 'package:crypto_king/domain/repositories/balance_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class HomeViewModel extends ChangeNotifier {
  final BalanceRepository _balanceRepo;
  static final _uuidGen = const Uuid();

  HomeViewModel({required BalanceRepository balanceRepo})
    : _balanceRepo = balanceRepo;

  List<Miner> miners = [];
  Map<String, int> remaining = {};
  Timer? _timer;

  int _maxSlots = 1;

  static const Map<int, int> slotCosts = {2: 100, 3: 1000};
  static const int maxTotalSlots = 3;
  static const Map<int, int> upgradeCosts = {1: 20, 2: 150};

  int get balance => _balanceRepo.balance;
  int get maxSlots => _maxSlots;
  int get nextSlotCost => slotCosts[_maxSlots + 1] ?? 0;
  bool get canBuySlot => _maxSlots < maxTotalSlots && balance >= nextSlotCost;

  double get coinsPerMinute {
    if (miners.isEmpty) return 0;
    double total = 0;
    for (final m in miners) {
      total += m.incomePerCycle * 60 / m.cycleSeconds;
    }
    return total;
  }

  bool canUpgrade(Miner miner) {
    final cost = upgradeCosts[miner.lvl];
    return cost != null && balance >= cost;
  }

  void init() {
    miners = MockData.miners;
    remaining = {for (final m in miners) m.id: m.cycleSeconds};
    _startCycle();
    notifyListeners();
  }

  void buySlot() {
    if (!canBuySlot) return;
    _balanceRepo.subtract(nextSlotCost);
    _maxSlots++;
    final newMiner = Miner(_uuidGen.v4(), 1);
    miners = [...miners, newMiner];
    remaining[newMiner.id] = newMiner.cycleSeconds;
    notifyListeners();
  }

  void upgradeMiner(String id) {
    final index = miners.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final miner = miners[index];
    final cost = upgradeCosts[miner.lvl];
    if (cost == null || balance < cost) return;

    _balanceRepo.subtract(cost);
    miners[index] = Miner(miner.id, miner.lvl + 1);
    remaining[id] = miners[index].cycleSeconds;
    notifyListeners();
  }

  void addReward(int amount) {
    _balanceRepo.add(amount);
    notifyListeners();
  }

  void _startCycle() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      for (final miner in miners) {
        final id = miner.id;
        if (remaining[id]! > 1) {
          remaining[id] = remaining[id]! - 1;
        } else {
          _balanceRepo.add(miner.incomePerCycle);
          remaining[id] = miner.cycleSeconds;
        }
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
