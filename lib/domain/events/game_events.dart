import '../models/game.dart';

/// Polymorphic game event — each event type knows how to apply and remove itself.
///
/// Replaces string-based switch in EventSystem.  Events that need restore data
/// (MarketCrash, MiningBoom, FomoRally, FreePower) store it as typed fields.
abstract class GameEvent {
  final String id;
  final String name;
  final String description;
  final String category;
  final int durationTicks;
  final int remainingTicks;

  const GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.durationTicks,
    required this.remainingTicks,
  });

  bool get isExpired => durationTicks > 0 && remainingTicks <= 0;
  bool get isInstant => durationTicks == 0;

  /// Called when the event starts.
  Game onApply(Game game);

  /// Called every tick while active.  Default: no-op.
  Game onTick(Game game) => game;

  /// Called when the event expires.
  Game onRemove(Game game) => game;

  /// Returns a copy with updated remaining ticks.
  GameEvent withRemaining(int ticks);

  /// If this event affects a specific coin, returns its index (for UI overlay).
  int? get coinIdx => null;
}

// ── Rig Events ─────────────────────────────────────────────────────

class DustStormEvent extends GameEvent {
  const DustStormEvent({int remainingTicks = 90})
    : super(
        id: 'dust',
        name: 'Dust Storm',
        description: 'All GPUs overheat by +15°C.',
        category: 'rig',
        durationTicks: 90,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g;
  @override
  GameEvent withRemaining(int t) => DustStormEvent(remainingTicks: t);
}

class FanFailureEvent extends GameEvent {
  const FanFailureEvent({int remainingTicks = 60})
    : super(
        id: 'fan_fail',
        name: 'Fan Failure',
        description: 'One GPU runs +25°C hotter.',
        category: 'rig',
        durationTicks: 60,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g;
  @override
  GameEvent withRemaining(int t) => FanFailureEvent(remainingTicks: t);
}

class OverheatEvent extends GameEvent {
  const OverheatEvent({int remainingTicks = 0})
    : super(
        id: 'overheat',
        name: 'Overheat',
        description: 'All GPUs take -5% condition instantly.',
        category: 'rig',
        durationTicks: 0,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game game) {
    final list = game.farm.gpuList
        .map((g) => g.copyWith(condition: (g.condition - 0.05).clamp(0, 1)))
        .toList();
    return game.copyWith(farm: game.farm.copyWith(gpuList: list));
  }

  @override
  GameEvent withRemaining(int t) => OverheatEvent(remainingTicks: t);
}

class PowerSurgeEvent extends GameEvent {
  const PowerSurgeEvent({int remainingTicks = 60})
    : super(
        id: 'power_surge',
        name: 'Power Surge',
        description: 'Electricity cost doubled for 60s.',
        category: 'rig',
        durationTicks: 60,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g.copyWith(electricityRate: g.electricityRate * 2);
  @override
  Game onRemove(Game g) => g.copyWith(electricityRate: g.electricityRate / 2);
  @override
  GameEvent withRemaining(int t) => PowerSurgeEvent(remainingTicks: t);
}

// ── Market Events ──────────────────────────────────────────────────

class GpuSaleEvent extends GameEvent {
  const GpuSaleEvent({int remainingTicks = 120})
    : super(
        id: 'gpu_sale',
        name: 'GPU Sale',
        description: 'GPU prices reduced by 30%.',
        category: 'market',
        durationTicks: 120,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g;
  @override
  GameEvent withRemaining(int t) => GpuSaleEvent(remainingTicks: t);
}

/// Shared helper for events that modify a coin price and restore it on expiry.
abstract class _CoinPriceEvent extends GameEvent {
  final int coinIdx;
  final double oldPrice;

  const _CoinPriceEvent({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.durationTicks,
    required super.remainingTicks,
    required this.coinIdx,
    required this.oldPrice,
  });

  double priceMultiplier();

  @override
  Game onApply(Game game) {
    if (coinIdx >= game.coins.length) return game;
    final newCoins = [...game.coins];
    newCoins[coinIdx] = game.coins[coinIdx].copyWith(
      price: (game.coins[coinIdx].price * priceMultiplier()).clamp(
        0.01,
        999999,
      ),
    );
    return game.copyWith(coins: newCoins);
  }

  @override
  Game onRemove(Game game) {
    if (coinIdx >= game.coins.length) return game;
    final newCoins = [...game.coins];
    newCoins[coinIdx] = game.coins[coinIdx].copyWith(price: oldPrice);
    return game.copyWith(coins: newCoins);
  }
}

class MarketCrashEvent extends _CoinPriceEvent {
  const MarketCrashEvent({
    int remainingTicks = 120,
    required int coinIdx,
    required double oldPrice,
  }) : super(
         id: 'market_crash',
         name: 'Market Crash',
         description: 'Panic selling! Coin price drops 40%.',
         category: 'market',
         durationTicks: 120,
         remainingTicks: remainingTicks,
         coinIdx: coinIdx,
         oldPrice: oldPrice,
       );
  @override
  double priceMultiplier() => 0.6;
  @override
  GameEvent withRemaining(int t) =>
      MarketCrashEvent(remainingTicks: t, coinIdx: coinIdx, oldPrice: oldPrice);
}

class MiningBoomEvent extends _CoinPriceEvent {
  const MiningBoomEvent({
    int remainingTicks = 120,
    required int coinIdx,
    required double oldPrice,
  }) : super(
         id: 'mining_boom',
         name: 'Mining Boom',
         description: 'Coin price surges +30%.',
         category: 'market',
         durationTicks: 120,
         remainingTicks: remainingTicks,
         coinIdx: coinIdx,
         oldPrice: oldPrice,
       );
  @override
  double priceMultiplier() => 1.3;
  @override
  GameEvent withRemaining(int t) =>
      MiningBoomEvent(remainingTicks: t, coinIdx: coinIdx, oldPrice: oldPrice);
}

class FomoRallyEvent extends _CoinPriceEvent {
  const FomoRallyEvent({
    int remainingTicks = 90,
    required int coinIdx,
    required double oldPrice,
  }) : super(
         id: 'fomo_rally',
         name: 'FOMO Rally',
         description: 'Everyone buying! Coin +50%.',
         category: 'market',
         durationTicks: 90,
         remainingTicks: remainingTicks,
         coinIdx: coinIdx,
         oldPrice: oldPrice,
       );
  @override
  double priceMultiplier() => 1.5;
  @override
  GameEvent withRemaining(int t) =>
      FomoRallyEvent(remainingTicks: t, coinIdx: coinIdx, oldPrice: oldPrice);
}

// ── City Events ────────────────────────────────────────────────────

class TaxBreakEvent extends GameEvent {
  const TaxBreakEvent({int remainingTicks = 120})
    : super(
        id: 'tax_break',
        name: 'Tax Break',
        description: 'Electricity cost -50% for 120s.',
        category: 'city',
        durationTicks: 120,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g.copyWith(electricityRate: g.electricityRate * 0.5);
  @override
  Game onRemove(Game g) => g.copyWith(electricityRate: g.electricityRate / 0.5);
  @override
  GameEvent withRemaining(int t) => TaxBreakEvent(remainingTicks: t);
}

class JobFairEvent extends GameEvent {
  const JobFairEvent({int remainingTicks = 90})
    : super(
        id: 'job_fair',
        name: 'Job Fair',
        description: 'All jobs pay double salary for 90s!',
        category: 'city',
        durationTicks: 90,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g;
  @override
  GameEvent withRemaining(int t) => JobFairEvent(remainingTicks: t);
}

class RentHikeEvent extends GameEvent {
  const RentHikeEvent({int remainingTicks = 120})
    : super(
        id: 'rent_hike',
        name: 'Rent Hike',
        description: 'Office rent doubled for 120s.',
        category: 'city',
        durationTicks: 120,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g;
  @override
  GameEvent withRemaining(int t) => RentHikeEvent(remainingTicks: t);
}

class FreePowerEvent extends GameEvent {
  final double oldRate;

  const FreePowerEvent({int remainingTicks = 60, required this.oldRate})
    : super(
        id: 'free_power',
        name: 'Free Power',
        description: 'Electricity cost \$0 for 60s!',
        category: 'city',
        durationTicks: 60,
        remainingTicks: remainingTicks,
      );
  @override
  Game onApply(Game g) => g.copyWith(electricityRate: 0);
  @override
  Game onRemove(Game game) => game.copyWith(electricityRate: oldRate);
  @override
  GameEvent withRemaining(int t) =>
      FreePowerEvent(remainingTicks: t, oldRate: oldRate);
}
