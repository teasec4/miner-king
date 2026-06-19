import '../catalogs/investment_catalog.dart';
import '../models/game.dart';
import '../models/investment.dart';

class InvestmentSystem {
  InvestmentSystem._();

  static Game update(Game game) {
    if (game.activeInvestments.isEmpty) return game;

    final updated = <ActiveInvestment>[];
    var money = game.money;

    for (final inv in game.activeInvestments) {
      final left = inv.ticksLeft - 1;
      if (left <= 0) {
        // Matured - return principal + profit
        final invest = InvestmentCatalog.byId(inv.investId);
        if (invest != null) {
          money += inv.amount * (1 + invest.returnRate);
        }
      } else {
        updated.add(
          ActiveInvestment(
            investId: inv.investId,
            amount: inv.amount,
            ticksLeft: left,
          ),
        );
      }
    }

    return game.copyWith(money: money, activeInvestments: updated);
  }
}
