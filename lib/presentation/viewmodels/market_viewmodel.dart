import 'package:crypto_king/data/gamestate.dart';
import 'package:crypto_king/domain/events/game_events.dart';
import 'package:crypto_king/domain/models/coinstate.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/systems/market_system.dart';

/// ViewModel for the Market tab: coins, prices, mood, events.
class MarketViewModel {
  final GameState state;
  MarketViewModel(this.state);
  Game get game => state.game;

  List<CoinState> get coins => game.coins;
  CoinState? coinState(String id) => game.coin(id);
  double get marketMood => game.marketMood;

  List<GameEvent> get activeEvents => game.activeEvents;

  GameEvent? eventForCoin(int coinIdx) {
    for (final e in game.activeEvents) {
      if (e.coinIdx == coinIdx) return e;
    }
    return null;
  }

  String moodLabel(double mood) => MarketSystem.mood(mood);
  String phaseLabel(dynamic phase) => MarketSystem.phase(phase);
  String phaseIcon(dynamic phase) => MarketSystem.icon(phase);
}
