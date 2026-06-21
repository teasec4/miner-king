import 'package:crypto_king/domain/events/game_events.dart';
import 'package:crypto_king/domain/models/coin_state.dart';
import 'package:crypto_king/domain/models/game.dart';
import 'package:crypto_king/domain/systems/market_system.dart';
import 'package:crypto_king/presentation/notifiers/notifiers.dart';

/// ViewModel for the Market tab: coins, prices, mood, events.
class MarketViewModel {
  final MarketNotifier _n;
  MarketViewModel(this._n);
  Game get game => _n.game;
  GameState get state => _n.state;

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
