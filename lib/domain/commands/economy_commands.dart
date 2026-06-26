import '../config/game_config.dart';
import '../catalogs/loan_catalog.dart';
import '../models/game.dart';
import '../models/loan.dart';
import '../systems/economy_system.dart';

/// Pure functions for economy operations: coins, loans.
class EconomyCommands {
  EconomyCommands._();

  // ── Coin trading ──

  static Game sellCoin(Game game, String coinId) {
    return EconomySystem.sellCoin(game, coinId);
  }

  static Game sellAllCoins(Game game) {
    return EconomySystem.sellAllCoins(game);
  }

  static Game? buyCoinWithCash(Game game, String coinId, double cashAmount) {
    return EconomySystem.buyCoinWithCash(game, coinId, cashAmount);
  }

  static Game? sellCoinForCash(Game game, String coinId, double coinAmount) {
    return EconomySystem.sellCoinForCash(game, coinId, coinAmount);
  }

  static Game? swapCoins(Game game, String fromId, String toId, double amount) {
    return EconomySystem.swapCoins(game, fromId, toId, amount);
  }

  // ── Loans ──

  static (Game, bool) takeLoan(Game game, String loanId) {
    final template = LoanCatalog.byId(loanId);
    if (template == null) return (game, false);
    if (game.activeLoans.any((l) => l.id == loanId)) return (game, false);

    final tiers = ['small', 'medium', 'large'];
    final idx = tiers.indexOf(loanId);
    if (idx > 0) {
      final prevRepayments = game.loanRepayments[tiers[idx - 1]] ?? 0;
      if (prevRepayments < 2) return (game, false);
    }

    final loan = Loan(
      id: template.id,
      name: template.name,
      principal: template.principal,
      interestPerMinute: template.interestPerMinute,
    )..remaining = template.principal * (1 + GameConfig.loanOriginationFee);

    return (
      game.copyWith(
        money: game.money + loan.principal,
        activeLoans: [...game.activeLoans, loan],
      ),
      true,
    );
  }

  static (Game, bool) repayLoan(Game game, String loanId, double amount) {
    final index = game.activeLoans.indexWhere((l) => l.id == loanId);
    if (index == -1) return (game, false);
    final loan = game.activeLoans[index];
    final toPay = amount.clamp(0, loan.remaining);
    if (game.money < toPay) return (game, false);

    final newLoans = [...game.activeLoans];
    final newRemaining = loan.remaining - toPay;
    if (newRemaining <= 0.01) {
      final reps = Map<String, int>.from(game.loanRepayments);
      reps[loanId] = (reps[loanId] ?? 0) + 1;
      newLoans.removeAt(index);
      return (
        game.copyWith(
          money: game.money - toPay,
          activeLoans: newLoans,
          loanRepayments: reps,
        ),
        true,
      );
    }
    newLoans[index] = loan.copyWith(remaining: newRemaining);
    return (
      game.copyWith(money: game.money - toPay, activeLoans: newLoans),
      true,
    );
  }
}
