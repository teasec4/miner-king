import 'package:flutter/foundation.dart';
import '../../data/game_state.dart';
import '../../domain/models/game.dart';

/// Notifies listeners when rig-relevant data changes (GPUs, farm, temps, slots).
class RigNotifier extends ChangeNotifier {
  final GameState state;
  RigNotifier(this.state);
  Game get game => state.game;
}

/// Notifies listeners when economy data changes (money, holdings, loans, electricity).
class EconomyNotifier extends ChangeNotifier {
  final GameState state;
  EconomyNotifier(this.state);
  Game get game => state.game;
}

/// Notifies listeners when market data changes (coin prices, mood, events).
class MarketNotifier extends ChangeNotifier {
  final GameState state;
  MarketNotifier(this.state);
  Game get game => state.game;
}

/// Notifies listeners when city/life data changes (jobs, courses, office, employees).
class CityNotifier extends ChangeNotifier {
  final GameState state;
  CityNotifier(this.state);
  Game get game => state.game;
}
