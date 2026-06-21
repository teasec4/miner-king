import 'market_phase.dart';

/// Runtime state for one coin on the market.
class CoinState {
  final String id;
  final String name;
  final double baseReward; // mining multiplier (1.0 = standard)
  final double volatility; // price swing multiplier (1.0 = standard)
  final bool eventImmune; // stablecoins immune to events
  final double crashChance; // weight for crash events (0-10)
  final double boomChance; // weight for boom events (0-10)
  final double microEventRate; // per-tick chance of micro price event
  final double price;
  final MarketPhase phase;
  final int phaseTicksLeft;

  CoinState({
    required this.id,
    required this.name,
    required this.baseReward,
    required this.volatility,
    required this.price,
    this.eventImmune = false,
    this.crashChance = 1.0,
    this.boomChance = 1.0,
    this.microEventRate = 0.005,
    this.phase = MarketPhase.sideways,
    this.phaseTicksLeft = 120,
  });

  CoinState copyWith({
    String? id,
    String? name,
    double? baseReward,
    double? volatility,
    double? price,
    MarketPhase? phase,
    int? phaseTicksLeft,
  }) {
    return CoinState(
      id: id ?? this.id,
      name: name ?? this.name,
      baseReward: baseReward ?? this.baseReward,
      volatility: volatility ?? this.volatility,
      price: price ?? this.price,
      eventImmune: eventImmune,
      crashChance: crashChance,
      boomChance: boomChance,
      microEventRate: microEventRate,
      phase: phase ?? this.phase,
      phaseTicksLeft: phaseTicksLeft ?? this.phaseTicksLeft,
    );
  }
}
