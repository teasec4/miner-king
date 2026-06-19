import '../models/game.dart';
import '../models/gpu_instance.dart';

/// Manages loans: interest accrual, repayment, risk.
class CreditSystem {
  CreditSystem._();

  /// Apply interest to all active loans each tick.
  static Game update(Game game) {
    if (game.activeLoans.isEmpty) return game;

    final updatedLoans = game.activeLoans.map((loan) {
      // Interest per tick = per-minute rate / 60
      final interest = loan.remaining * (loan.interestPerMinute / 60);
      return loan.copyWith(remaining: loan.remaining + interest);
    }).toList();

    // Check for seizure: if total debt > 2x net worth, seize most expensive GPU
    var g = game.copyWith(activeLoans: updatedLoans);
    final netWorth = g.money + _holdingsValue(g);
    final totalDebt = _totalDebt(g);

    if (totalDebt > netWorth * 2 && g.farm.gpuList.isNotEmpty) {
      // Seize the GPU with highest model price
      final seized = _mostExpensiveGpu(g);
      if (seized != null) {
        final newList = g.farm.gpuList
            .where((gpu) => gpu.id != seized.id)
            .toList();
        // Selling seized GPU reduces debt by 50% of its price
        final value = _gpuPrice(seized.modelId) * 0.5;
        final remainingDebt = (totalDebt - value).clamp(0, double.infinity);
        // Reduce debt proportionally across loans
        final reducedLoans = g.activeLoans.map((l) {
          final share = l.remaining / totalDebt;
          return l.copyWith(remaining: l.remaining - remainingDebt * share);
        }).toList();
        g = g.copyWith(
          farm: g.farm.copyWith(gpuList: newList),
          activeLoans: reducedLoans,
        );
      }
    }

    return g;
  }

  static double _totalDebt(Game game) {
    return game.activeLoans.fold(0, (sum, l) => sum + l.remaining);
  }

  static double _holdingsValue(Game game) {
    return game.coins.fold(0, (sum, c) {
      return sum + (game.holdings[c.id] ?? 0) * c.price;
    });
  }

  static double totalDebt(Game game) => _totalDebt(game);

  static GpuInstance? _mostExpensiveGpu(Game game) {
    GpuInstance? result;
    double maxPrice = 0;
    for (final gpu in game.farm.gpuList) {
      final price = _gpuPrice(gpu.modelId);
      if (price > maxPrice) {
        maxPrice = price;
        result = gpu;
      }
    }
    return result;
  }

  static double _gpuPrice(String modelId) {
    switch (modelId) {
      case 'gtx_1060':
        return 200;
      case 'rtx_2060':
        return 500;
      case 'rtx_3070':
        return 1200;
      case 'rtx_5090':
        return 5000;
      default:
        return 100;
    }
  }
}
