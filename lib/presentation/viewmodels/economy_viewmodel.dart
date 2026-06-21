import 'package:crypto_king/data/game_state.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/models/loan.dart';
import 'package:crypto_king/domain/systems/credit_system.dart';
import 'package:crypto_king/domain/systems/electricity_system.dart';
import 'package:crypto_king/domain/systems/mining_system.dart';
import 'package:crypto_king/presentation/notifiers/notifiers.dart';

/// ViewModel for economy: money, holdings, electricity, loans.
class EconomyViewModel {
  final EconomyNotifier _n;
  EconomyViewModel(this._n);
  Game get game => _n.game;
  GameState get state => _n.state;

  double get money => game.money;
  double get electricityRate => game.electricityRate;

  double get electricityCostPerHour => ElectricitySystem.costPerHour(game);
  double get electricityCostPerMin => electricityCostPerHour / 60;

  double get netProfitPerMin {
    double revenue = 0;
    for (final gpu in game.farm.gpuList) {
      revenue += MiningSystem.revenuePerMin(gpu, game);
    }
    return revenue - electricityCostPerMin;
  }

  // ── Holdings ──

  double holding(String coinId) => game.holdings[coinId] ?? 0;
  List<CoinState> get coins => game.coins;
  CoinState? coinState(String id) => game.coin(id);

  double holdingValue(String coinId) {
    final c = game.coin(coinId);
    return (c?.price ?? 0) * holding(coinId);
  }

  double get totalHoldingsValue {
    return game.coins.fold(0, (sum, c) => sum + holdingValue(c.id));
  }

  bool canSellCoin(String coinId) => holding(coinId) > 0;

  // ── Loans ──

  List<Loan> get activeLoans => game.activeLoans;
  Map<String, int> get loanRepayments => game.loanRepayments;
  double get totalDebt => CreditSystem.totalDebt(game);

  bool isLoanUnlocked(String loanId) {
    final tiers = ['small', 'medium', 'large'];
    final idx = tiers.indexOf(loanId);
    if (idx <= 0) return true;
    return (game.loanRepayments[tiers[idx - 1]] ?? 0) >= 2;
  }

  // ── Actions ──

  void sellCoin(String id) => state.sellCoin(id);
  void sellAllCoins() => state.sellAllCoins();
  bool buyCoinWithCash(String id, double cash) =>
      state.buyCoinWithCash(id, cash);
  bool sellCoinForCash(String id, double amount) =>
      state.sellCoinForCash(id, amount);
  bool swapCoins(String from, String to, double amount) =>
      state.swapCoins(from, to, amount);
  bool takeLoan(String id) => state.takeLoan(id);
  bool repayLoan(String id, double amount) => state.repayLoan(id, amount);
}
