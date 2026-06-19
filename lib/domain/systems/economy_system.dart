import '../models/game.dart';

/// Handles economic operations: buying, selling, upgrading.
class EconomySystem {
  EconomySystem._();

  /// Sell all of a specific coin for money at current price.
  static Game sellCoin(Game game, String coinId) {
    final coin = game.coin(coinId);
    final amount = game.holdings[coinId] ?? 0;
    if (coin == null || amount <= 0) return game;

    final earnings = amount * coin.price;
    final newHoldings = Map<String, double>.from(game.holdings);
    newHoldings[coinId] = 0;

    return game.copyWith(money: game.money + earnings, holdings: newHoldings);
  }

  /// Sell all coins of all types.
  static Game sellAllCoins(Game game) {
    var g = game;
    for (final coin in game.coins) {
      g = sellCoin(g, coin.id);
    }
    return g;
  }
}
