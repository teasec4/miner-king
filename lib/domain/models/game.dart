import 'coin_state.dart';
import 'farm.dart';
import 'game_event.dart';
import 'modifier.dart';

/// Root aggregate – contains all game state.
class Game {
  final double money; // $
  final Map<String, double> holdings; // coinId → amount
  final List<CoinState> coins; // market state for each coin
  final double electricityRate; // $ per kWh
  final Farm farm;
  final List<Modifier> activeModifiers;
  final List<GameEvent> activeEvents;
  final int tick; // current tick counter

  const Game({
    required this.money,
    required this.holdings,
    required this.coins,
    required this.farm,
    this.electricityRate = 0.12,
    this.activeModifiers = const [],
    this.activeEvents = const [],
    this.tick = 0,
  });

  /// Convenience: get a single coin's state.
  CoinState? coin(String id) {
    try {
      return coins.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Convenience: first coin (for backward compatibility).
  CoinState get primaryCoin => coins.first;

  Game copyWith({
    double? money,
    Map<String, double>? holdings,
    List<CoinState>? coins,
    double? electricityRate,
    Farm? farm,
    List<Modifier>? activeModifiers,
    List<GameEvent>? activeEvents,
    int? tick,
  }) {
    return Game(
      money: money ?? this.money,
      holdings: holdings ?? this.holdings,
      coins: coins ?? this.coins,
      electricityRate: electricityRate ?? this.electricityRate,
      farm: farm ?? this.farm,
      activeModifiers: activeModifiers ?? this.activeModifiers,
      activeEvents: activeEvents ?? this.activeEvents,
      tick: tick ?? this.tick,
    );
  }
}
