import '../models/game.dart';

/// Handles economic operations: buying, selling, upgrading.
class EconomySystem {
  EconomySystem._();

  /// Sell all coins for money at current price.
  static Game sellAllCoins(Game game) {
    if (game.coins <= 0) return game;
    final earnings = game.coins * game.coinPrice;
    return game.copyWith(money: game.money + earnings, coins: 0);
  }

  /// Sell a portion of coins.
  static Game sellCoins(Game game, double amount) {
    final toSell = amount.clamp(0, game.coins);
    final earnings = toSell * game.coinPrice;
    return game.copyWith(
      money: game.money + earnings,
      coins: game.coins - toSell,
    );
  }

  /// Try to buy a GPU – returns game with GPU added if affordable and slots free.
  static Game? buyGpu(Game game, String modelId, String instanceId) {
    // TODO: resolve model from catalog and check price/slots
    return null; // will implement when shop is added
  }
}
