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

  /// Swap one coin for another at market rates.
  /// Uses a 1% spread (slight disadvantage to prevent arbitrage loops).
  static Game? swapCoins(Game game, String fromId, String toId, double amount) {
    if (fromId == toId) return null;
    final fromCoin = game.coin(fromId);
    final toCoin = game.coin(toId);
    final fromBalance = game.holdings[fromId] ?? 0;
    if (fromCoin == null ||
        toCoin == null ||
        amount <= 0 ||
        fromBalance < amount) {
      return null;
    }

    // Value in USD, with 1% fee
    final usdValue = amount * fromCoin.price * 0.99;
    final toAmount = usdValue / toCoin.price;

    final newHoldings = Map<String, double>.from(game.holdings);
    newHoldings[fromId] = (newHoldings[fromId] ?? 0) - amount;
    newHoldings[toId] = (newHoldings[toId] ?? 0) + toAmount;

    return game.copyWith(holdings: newHoldings);
  }
}
