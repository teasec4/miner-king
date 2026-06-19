import 'dart:math';
import '../models/game.dart';
import '../models/market_phase.dart';

class MarketSystem {
  MarketSystem._();
  static final _r = Random();
  static const _minPhase = 60, _maxPhase = 300;

  static Game update(Game game) {
    var mood = game.marketMood;
    mood += (_r.nextDouble() - 0.5) * 0.03;
    mood -= mood * 0.002; // stronger mean reversion
    mood = mood.clamp(-1.0, 1.0);

    final updatedCoins = game.coins.map((coin) {
      var phase = coin.phase;
      var ticksLeft = coin.phaseTicksLeft;
      var price = coin.price;

      ticksLeft--;
      if (ticksLeft <= 0) {
        phase = _nextPhase(phase, mood);
        ticksLeft = _minPhase + _r.nextInt(_maxPhase - _minPhase);
      }

      // Smooth drift: smaller and noisier than before
      final drift = _drift(phase, coin.volatility, mood);
      price = (price * (1 + drift)).clamp(0.01, 999999.0);

      // Micro-shocks: rare, significant swings (fat tails)
      if (coin.microEventRate > 0 &&
          _r.nextDouble() < coin.microEventRate * 1.5) {
        // Bias toward crashes for volatile coins
        final crashBias = coin.volatility > 2 ? 0.55 : 0.48;
        final shock = (_r.nextDouble() - crashBias) * coin.volatility * 0.12;
        price = (price * (1 + shock)).clamp(0.01, 999999.0);
      }

      // Rare volatility explosion: big swing for volatile coins
      if (coin.volatility > 2 && _r.nextDouble() < 0.0005) {
        final explosion = (_r.nextDouble() - 0.52) * coin.volatility * 0.4;
        price = (price * (1 + explosion)).clamp(0.01, 999999.0);
      }

      return coin.copyWith(
        phase: phase,
        phaseTicksLeft: ticksLeft,
        price: double.parse(price.toStringAsFixed(2)),
      );
    }).toList();

    return game.copyWith(coins: updatedCoins, marketMood: mood);
  }

  static MarketPhase _nextPhase(MarketPhase current, double mood) {
    final others = MarketPhase.values.where((p) => p != current).toList();
    if (mood > 0.3 && _r.nextDouble() < mood) return MarketPhase.bull;
    if (mood < -0.3 && _r.nextDouble() < -mood) return MarketPhase.bear;
    return others[_r.nextInt(others.length)];
  }

  /// Smaller, less predictable drift.
  static double _drift(MarketPhase phase, double vol, double mood) {
    final base = switch (phase) {
      MarketPhase.bull => (_r.nextDouble() * 0.004 + 0.001),
      MarketPhase.bear => -(_r.nextDouble() * 0.004 + 0.001),
      MarketPhase.sideways => (_r.nextDouble() - 0.5) * 0.004,
    };
    // Mood amplifies but less aggressively
    final amp = 1 + mood.abs() * 0.3;
    // Add noise: random wiggle
    final noise = (_r.nextDouble() - 0.5) * 0.003 * vol;
    return (base + noise) * vol * amp;
  }

  static String moodLabel(double mood) {
    if (mood > 0.6) return 'Extreme Greed';
    if (mood > 0.2) return 'Greed';
    if (mood > -0.2) return 'Neutral';
    if (mood > -0.6) return 'Fear';
    return 'Extreme Fear';
  }

  static String phaseLabel(MarketPhase phase) => switch (phase) {
    MarketPhase.bull => 'Bull',
    MarketPhase.bear => 'Bear',
    MarketPhase.sideways => 'Sideways',
  };
  static String phaseIcon(MarketPhase phase) => switch (phase) {
    MarketPhase.bull => '\u2191',
    MarketPhase.bear => '\u2193',
    MarketPhase.sideways => '\u2192',
  };
}
