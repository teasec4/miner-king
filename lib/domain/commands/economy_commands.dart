import '../config/game_config.dart';
import '../catalogs/investment_catalog.dart';
import '../catalogs/loan_catalog.dart';
import '../catalogs/property_catalog.dart';
import '../models/game.dart';
import '../models/investment.dart';
import '../models/loan.dart';

/// Pure functions for economy operations: coins, loans, investments, property.
class EconomyCommands {
  EconomyCommands._();

  // ── Coin trading ──

  static Game sellCoin(Game game, String coinId) {
    final coin = game.coin(coinId);
    final amount = game.holdings[coinId] ?? 0;
    if (coin == null || amount <= 0) return game;
    return game.copyWith(
      money: game.money + amount * coin.price,
      holdings: {...game.holdings, coinId: 0},
    );
  }

  static Game sellAllCoins(Game game) {
    var g = game;
    for (final coin in game.coins) {
      g = sellCoin(g, coin.id);
    }
    return g;
  }

  static Game? buyCoinWithCash(Game game, String coinId, double cashAmount) {
    final coin = game.coin(coinId);
    if (coin == null || cashAmount <= 0 || game.money < cashAmount) return null;
    final amount = cashAmount * (1 - GameConfig.cashExchangeFee) / coin.price;
    final newHoldings = Map<String, double>.from(game.holdings);
    newHoldings[coinId] = (newHoldings[coinId] ?? 0) + amount;
    return game.copyWith(money: game.money - cashAmount, holdings: newHoldings);
  }

  static Game? sellCoinForCash(Game game, String coinId, double coinAmount) {
    final coin = game.coin(coinId);
    final balance = game.holdings[coinId] ?? 0;
    if (coin == null || coinAmount <= 0 || balance < coinAmount) return null;
    final cash = coinAmount * coin.price * (1 - GameConfig.cashExchangeFee);
    return game.copyWith(
      money: game.money + cash,
      holdings: {...game.holdings, coinId: balance - coinAmount},
    );
  }

  static Game? swapCoins(Game game, String fromId, String toId, double amount) {
    if (fromId == toId) return null;
    final fromCoin = game.coin(fromId);
    final toCoin = game.coin(toId);
    final fromBalance = game.holdings[fromId] ?? 0;
    if (fromCoin == null ||
        toCoin == null ||
        amount <= 0 ||
        fromBalance < amount) {
      return null;
    }
    final usdValue = amount * fromCoin.price * (1 - GameConfig.swapFee);
    final toAmount = usdValue / toCoin.price;
    return game.copyWith(
      holdings: {
        ...game.holdings,
        fromId: (game.holdings[fromId] ?? 0) - amount,
        toId: (game.holdings[toId] ?? 0) + toAmount,
      },
    );
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

  // ── Investments ──

  static (Game, bool) invest(Game game, String investId, double amount) {
    final template = InvestmentCatalog.byId(investId);
    if (template == null) return (game, false);
    if (amount < template.minAmount) return (game, false);
    if (game.money < amount) return (game, false);
    final inv = ActiveInvestment(
      investId: investId,
      amount: amount,
      ticksLeft: template.durationTicks,
    );
    return (
      game.copyWith(
        money: game.money - amount,
        activeInvestments: [...game.activeInvestments, inv],
      ),
      true,
    );
  }

  // ── Property ──

  static (Game, bool) buyProperty(Game game, String propertyId) {
    final p = PropertyCatalog.byId(propertyId);
    if (p == null) return (game, false);
    if (game.money < p.price) return (game, false);
    if (game.properties.contains(propertyId)) return (game, false);
    return (
      game.copyWith(
        money: game.money - p.price,
        properties: [...game.properties, propertyId],
      ),
      true,
    );
  }
}
