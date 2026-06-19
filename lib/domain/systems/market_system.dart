import 'dart:math';

import '../models/game.dart';

/// Drives coin price fluctuations and market phase transitions.
class MarketSystem {
  MarketSystem._();

  static final _random = Random();

  // Phase durations (ticks)
  static const _minPhaseTicks = 60;
  static const _maxPhaseTicks = 300;

  /// Update coin price and possibly switch market phase.
  static Game update(Game game) {
    var phase = game.marketPhase;
    var ticksLeft = game.marketPhaseTicksLeft;
    var price = game.coinPrice;

    // ── Check for phase transition ──
    ticksLeft--;
    if (ticksLeft <= 0) {
      phase = _nextPhase(phase);
      ticksLeft =
          _minPhaseTicks + _random.nextInt(_maxPhaseTicks - _minPhaseTicks);
    }

    // ── Price movement ──
    final change = _priceChange(phase);
    price = (price * (1 + change)).clamp(1.0, 100.0);

    return game.copyWith(
      coinPrice: double.parse(price.toStringAsFixed(2)),
      marketPhase: phase,
      marketPhaseTicksLeft: ticksLeft,
    );
  }

  /// Pick a new phase (can't stay the same).
  static MarketPhase _nextPhase(MarketPhase current) {
    final others = MarketPhase.values.where((p) => p != current).toList();
    return others[_random.nextInt(others.length)];
  }

  /// Price change % for this tick based on phase.
  static double _priceChange(MarketPhase phase) {
    return switch (phase) {
      MarketPhase.bull =>
        (_random.nextDouble() * 0.008 + 0.002), // +0.2% to +1.0%
      MarketPhase.bear =>
        -(_random.nextDouble() * 0.008 + 0.002), // −0.2% to −1.0%
      MarketPhase.sideways => (_random.nextDouble() - 0.5) * 0.006, // ±0.3%
    };
  }

  /// Human-readable label for market phase.
  static String phaseLabel(MarketPhase phase) {
    return switch (phase) {
      MarketPhase.bull => 'Bull Market 🟢',
      MarketPhase.bear => 'Bear Market 🔴',
      MarketPhase.sideways => 'Sideways ⚪',
    };
  }

  /// Direction indicator for display.
  static String phaseIcon(MarketPhase phase) {
    return switch (phase) {
      MarketPhase.bull => '↑',
      MarketPhase.bear => '↓',
      MarketPhase.sideways => '→',
    };
  }
}
