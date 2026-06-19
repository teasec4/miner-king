import 'farm.dart';
import 'modifier.dart';

/// Root aggregate – contains all game state.
class Game {
  final double money; // $
  final double coins; // mined crypto
  final double coinPrice; // $ per coin
  final Farm farm;
  final List<Modifier> activeModifiers;
  final int tick; // current tick counter

  const Game({
    required this.money,
    required this.coins,
    required this.coinPrice,
    required this.farm,
    this.activeModifiers = const [],
    this.tick = 0,
  });

  Game copyWith({
    double? money,
    double? coins,
    double? coinPrice,
    Farm? farm,
    List<Modifier>? activeModifiers,
    int? tick,
  }) {
    return Game(
      money: money ?? this.money,
      coins: coins ?? this.coins,
      coinPrice: coinPrice ?? this.coinPrice,
      farm: farm ?? this.farm,
      activeModifiers: activeModifiers ?? this.activeModifiers,
      tick: tick ?? this.tick,
    );
  }
}
