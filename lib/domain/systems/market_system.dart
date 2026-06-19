import 'dart:math';
import '../models/game.dart';
import '../models/market_phase.dart';

class MarketSystem {
  MarketSystem._();
  static final _r = Random();
  static const _minPhase = 60, _maxPhase = 300;

  static Game update(Game game) {
    // Update global mood (random walk + mean reversion toward 0)
    var mood = game.marketMood;
    mood += (_r.nextDouble() - 0.5) * 0.02; // random walk
    mood -= mood * 0.001; // mean reversion
    mood = mood.clamp(-1.0, 1.0);

    // Update coins
    final updatedCoins = game.coins.map((coin) {
      var phase = coin.phase;
      var ticksLeft = coin.phaseTicksLeft;
      var price = coin.price;

      ticksLeft--;
      if (ticksLeft <= 0) {
        phase = _nextPhase(phase, mood);
        ticksLeft = _minPhase + _r.nextInt(_maxPhase - _minPhase);
      }

      // Price change: base volatility * mood amplification
      final change = _priceChange(phase, coin.volatility, mood);
      price = (price * (1 + change)).clamp(0.01, 10000.0);

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
    // Bias: positive mood → more bull, negative → more bear
    if (mood > 0.3 && _r.nextDouble() < mood) return MarketPhase.bull;
    if (mood < -0.3 && _r.nextDouble() < -mood) return MarketPhase.bear;
    return others[_r.nextInt(others.length)];
  }

  static double _priceChange(MarketPhase phase, double vol, double mood) {
    final base = switch (phase) {
      MarketPhase.bull => (_r.nextDouble() * 0.008 + 0.002),
      MarketPhase.bear => -(_r.nextDouble() * 0.008 + 0.002),
      MarketPhase.sideways => (_r.nextDouble() - 0.5) * 0.006,
    };
    // Mood amplifies: greed boosts bulls, fear deepens bears
    final amp = 1 + mood.abs() * 0.5;
    return base * vol * amp;
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
