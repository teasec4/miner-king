import '../models/game.dart';

/// Manages loans: interest accrual and repayment.
class CreditSystem {
  CreditSystem._();

  /// Apply interest to all active loans each tick.
  static Game update(Game game) {
    if (game.activeLoans.isEmpty) return game;

    final updatedLoans = game.activeLoans.map((loan) {
      final interest = loan.remaining * (loan.interestPerMinute / 60);
      return loan.copyWith(remaining: loan.remaining + interest);
    }).toList();

    return game.copyWith(activeLoans: updatedLoans);
  }

  static double totalDebt(Game game) {
    return game.activeLoans.fold(0, (sum, l) => sum + l.remaining);
  }
}
