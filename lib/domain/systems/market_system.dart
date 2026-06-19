import 'dart:math';

import '../models/game.dart';
import '../models/market_phase.dart';

/// Drives coin price fluctuations and market phase transitions for all coins.
class MarketSystem {
  MarketSystem._();

  static final _random = Random();

  static const _minPhaseTicks = 60;
  static const _maxPhaseTicks = 300;

  /// Update all coins' prices and possibly switch market phases.
  static Game update(Game game) {
    final updatedCoins = game.coins.map((coin) {
      var phase = coin.phase;
      var ticksLeft = coin.phaseTicksLeft;
      var price = coin.price;

      ticksLeft--;
      if (ticksLeft <= 0) {
        phase = _nextPhase(phase);
        ticksLeft =
            _minPhaseTicks + _random.nextInt(_maxPhaseTicks - _minPhaseTicks);
      }

      final change = _priceChange(phase, coin.volatility);
      price = (price * (1 + change)).clamp(0.01, 10000.0);

      return coin.copyWith(
        price: double.parse(price.toStringAsFixed(2)),
        phase: phase,
        phaseTicksLeft: ticksLeft,
      );
    }).toList();

    return game.copyWith(coins: updatedCoins);
  }

  static MarketPhase _nextPhase(MarketPhase current) {
    final others = MarketPhase.values.where((p) => p != current).toList();
    return others[_random.nextInt(others.length)];
  }

  static double _priceChange(MarketPhase phase, double volatility) {
    final base = switch (phase) {
      MarketPhase.bull => (_random.nextDouble() * 0.008 + 0.002),
      MarketPhase.bear => -(_random.nextDouble() * 0.008 + 0.002),
      MarketPhase.sideways => (_random.nextDouble() - 0.5) * 0.006,
    };
    return base * volatility;
  }

  static String phaseLabel(MarketPhase phase) {
    return switch (phase) {
      MarketPhase.bull => 'Bull Market 🟢',
      MarketPhase.bear => 'Bear Market 🔴',
      MarketPhase.sideways => 'Sideways ⚪',
    };
  }

  static String phaseIcon(MarketPhase phase) {
    return switch (phase) {
      MarketPhase.bull => '↑',
      MarketPhase.bear => '↓',
      MarketPhase.sideways => '→',
    };
  }
}
