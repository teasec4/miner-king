import 'dart:math';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/market_phase.dart';

/// Interface for market simulation (coin prices, mood, phases).
abstract class MarketSystem {
  Game update(Game game);

  String moodLabel(double mood);
  String phaseLabel(MarketPhase phase);
  String phaseIcon(MarketPhase phase);

  /// Static convenience — pure functions, no state needed.
  static String mood(double mood) {
    if (mood > 0.6) return 'Extreme Greed';
    if (mood > 0.2) return 'Greed';
    if (mood > -0.2) return 'Neutral';
    if (mood > -0.6) return 'Fear';
    return 'Extreme Fear';
  }

  static String phase(MarketPhase phase) => switch (phase) {
    MarketPhase.bull => 'Bull',
    MarketPhase.bear => 'Bear',
    MarketPhase.sideways => 'Sideways',
  };

  static String icon(MarketPhase phase) => switch (phase) {
    MarketPhase.bull => '\u2191',
    MarketPhase.bear => '\u2193',
    MarketPhase.sideways => '\u2192',
  };
}

class DefaultMarketSystem implements MarketSystem {
  final Random _r;

  DefaultMarketSystem({Random? random}) : _r = random ?? Random();

  @override
  Game update(Game game) {
    var mood = game.marketMood;
    mood += (_r.nextDouble() - 0.5) * GameConfig.moodRandomWalk;
    mood -= mood * GameConfig.moodMeanReversion;
    mood = mood.clamp(-1.0, 1.0);

    final updatedCoins = game.coins.map((coin) {
      var phase = coin.phase;
      var ticksLeft = coin.phaseTicksLeft;
      var price = coin.price;

      ticksLeft--;
      if (ticksLeft <= 0) {
        phase = _nextPhase(phase, mood);
        ticksLeft =
            GameConfig.minPhaseTicks +
            _r.nextInt(GameConfig.maxPhaseTicks - GameConfig.minPhaseTicks);
      }

      final drift = _drift(phase, coin.volatility, mood);
      price = (price * (1 + drift)).clamp(0.01, 999999.0);

      if (coin.microEventRate > 0 &&
          _r.nextDouble() <
              coin.microEventRate * GameConfig.microShockChanceMultiplier) {
        final crashBias = coin.volatility > 2 ? 0.55 : 0.48;
        final shock =
            (_r.nextDouble() - crashBias) *
            coin.volatility *
            GameConfig.microShockAmplitude;
        price = (price * (1 + shock)).clamp(0.01, 999999.0);
      }

      if (coin.volatility > 2 &&
          _r.nextDouble() < GameConfig.volatilityExplosionChance) {
        final explosion =
            (_r.nextDouble() - 0.52) *
            coin.volatility *
            GameConfig.volatilityExplosionAmplitude;
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

  MarketPhase _nextPhase(MarketPhase current, double mood) {
    final others = MarketPhase.values.where((p) => p != current).toList();
    if (mood > GameConfig.moodBiasThreshold &&
        _r.nextDouble() < mood * GameConfig.moodBiasProbabilityScalar) {
      return MarketPhase.bull;
    }
    if (mood < -GameConfig.moodBiasThreshold &&
        _r.nextDouble() < -mood * GameConfig.moodBiasProbabilityScalar) {
      return MarketPhase.bear;
    }
    return others[_r.nextInt(others.length)];
  }

  double _drift(MarketPhase phase, double vol, double mood) {
    final base = switch (phase) {
      MarketPhase.bull =>
        (_r.nextDouble() * GameConfig.driftBaseMagnitude +
            GameConfig.driftBaseOffset),
      MarketPhase.bear =>
        -(_r.nextDouble() * GameConfig.driftBaseMagnitude +
            GameConfig.driftBaseOffset),
      MarketPhase.sideways =>
        (_r.nextDouble() - 0.5) * GameConfig.driftBaseMagnitude,
    };
    final amp = 1 + mood.abs() * GameConfig.driftMoodAmplifier;
    final noise =
        (_r.nextDouble() - 0.5) * GameConfig.driftNoiseMultiplier * vol;
    return (base + noise) * vol * amp;
  }

  @override
  String moodLabel(double m) => MarketSystem.mood(m);

  @override
  String phaseLabel(MarketPhase p) => MarketSystem.phase(p);

  @override
  String phaseIcon(MarketPhase p) => MarketSystem.icon(p);
}
