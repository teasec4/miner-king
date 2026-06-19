import '../models/coin_state.dart';

/// Static catalog of all available coins.
class CoinCatalog {
  CoinCatalog._();

  static final btc = CoinState(
    id: 'btc',
    name: 'BTC',
    baseReward: 1.0,
    volatility: 1.0,
    price: 10.0,
  );

  static final eth = CoinState(
    id: 'eth',
    name: 'ETH',
    baseReward: 1.5,
    volatility: 0.8,
    price: 5.0,
  );

  static final doge = CoinState(
    id: 'doge',
    name: 'DOGE',
    baseReward: 0.5,
    volatility: 2.5,
    price: 1.0,
  );

  static final sol = CoinState(
    id: 'sol',
    name: 'SOL',
    baseReward: 1.2,
    volatility: 1.8,
    price: 3.0,
  );

  static final pepe = CoinState(
    id: 'pepe',
    name: 'PEPE',
    baseReward: 3.0,
    volatility: 5.0,
    price: 0.10,
  );

  static final List<CoinState> all = [btc, eth, sol, doge, pepe];

  static CoinState? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create initial runtime coins from catalog (deep copy).
  static List<CoinState> initialCoins() {
    return all
        .map(
          (c) => CoinState(
            id: c.id,
            name: c.name,
            baseReward: c.baseReward,
            volatility: c.volatility,
            price: c.price,
          ),
        )
        .toList();
  }
}
