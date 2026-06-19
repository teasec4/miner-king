import 'farm.dart';
import 'modifier.dart';

/// Root aggregate – contains all game state.
class Game {
  final double money; // $
  final double coins; // mined crypto
  final double coinPrice; // $ per coin
  final double electricityRate; // $ per kWh
  final Farm farm;
  final List<Modifier> activeModifiers;
  final int tick; // current tick counter

  const Game({
    required this.money,
    required this.coins,
    required this.coinPrice,
    required this.farm,
    this.electricityRate = 0.12,
    this.activeModifiers = const [],
    this.tick = 0,
  });

  Game copyWith({
    double? money,
    double? coins,
    double? coinPrice,
    double? electricityRate,
    Farm? farm,
    List<Modifier>? activeModifiers,
    int? tick,
  }) {
    return Game(
      money: money ?? this.money,
      coins: coins ?? this.coins,
      coinPrice: coinPrice ?? this.coinPrice,
      electricityRate: electricityRate ?? this.electricityRate,
      farm: farm ?? this.farm,
      activeModifiers: activeModifiers ?? this.activeModifiers,
      tick: tick ?? this.tick,
    );
  }
}
