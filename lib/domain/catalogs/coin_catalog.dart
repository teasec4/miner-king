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
    crashChance: 0.5,
    boomChance: 0.7,
    microEventRate: 0.003,
  );

  static final eth = CoinState(
    id: 'eth',
    name: 'ETH',
    baseReward: 1.5,
    volatility: 0.8,
    price: 5.0,
    crashChance: 0.4,
    boomChance: 0.9,
    microEventRate: 0.004,
  );

  static final sol = CoinState(
    id: 'sol',
    name: 'SOL',
    baseReward: 1.2,
    volatility: 1.8,
    price: 3.0,
    crashChance: 1.5,
    boomChance: 2.0,
    microEventRate: 0.008,
  );

  static final doge = CoinState(
    id: 'doge',
    name: 'DOGE',
    baseReward: 0.5,
    volatility: 2.5,
    price: 1.0,
    crashChance: 3.0,
    boomChance: 3.0,
    microEventRate: 0.015,
  );

  static final pepe = CoinState(
    id: 'pepe',
    name: 'PEPE',
    baseReward: 3.0,
    volatility: 5.0,
    price: 0.10,
    crashChance: 6.0,
    boomChance: 6.0,
    microEventRate: 0.03,
  );

  static final usdt = CoinState(
    id: 'usdt',
    name: 'USDT',
    baseReward: 0.0, // can't mine stablecoins
    volatility: 0.03,
    price: 1.0,
    eventImmune: true,
    crashChance: 0,
    boomChance: 0,
    microEventRate: 0,
  );

  static final List<CoinState> all = [btc, eth, sol, doge, pepe, usdt];

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
            eventImmune: c.eventImmune,
            crashChance: c.crashChance,
            boomChance: c.boomChance,
            microEventRate: c.microEventRate,
          ),
        )
        .toList();
  }
}
