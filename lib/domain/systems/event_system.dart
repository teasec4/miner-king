import 'dart:math';

import '../catalogs/event_catalog.dart';
import '../models/game.dart';
import '../models/game_event.dart';

/// Triggers random events and manages active event durations.
class EventSystem {
  EventSystem._();

  static final _random = Random();

  /// Ticks until next event check (60–300 ticks = 1–5 minutes).
  static int _nextEventIn = 180;

  /// Update: tick active events, possibly trigger new one.
  /// Returns (game, newEvent or null).
  static (Game, GameEvent?) update(Game game) {
    var g = game;
    GameEvent? triggered;

    // ── Tick active events ──
    final updatedEvents = <GameEvent>[];
    for (final e in game.activeEvents) {
      if (e.isInstant) {
        // Instant events show for 60 ticks then auto-remove
        final remaining = e.remainingTicks - 1;
        if (remaining <= -60) continue; // expired
        updatedEvents.add(e.copyWith(remainingTicks: remaining));
      } else {
        final remaining = e.remainingTicks - 1;
        if (remaining <= 0) {
          g = _removeEvent(g, e);
        } else {
          updatedEvents.add(e.copyWith(remainingTicks: remaining));
        }
      }
    }
    g = g.copyWith(activeEvents: updatedEvents);

    // ── Trigger new event? ──
    _nextEventIn--;
    if (_nextEventIn <= 0) {
      _nextEventIn = 60 + _random.nextInt(240); // 1–5 min
      if (g.activeEvents.length < 3) {
        final event = _pickRandomEvent(g);
        if (event != null) {
          g = _applyEvent(g, event);
          triggered = event;
        }
      }
    }

    return (g, triggered);
  }

  static GameEvent? _pickRandomEvent(Game game) {
    var available = EventCatalog.all
        .where((e) => !game.activeEvents.any((a) => a.id == e.id))
        .toList();
    if (available.isEmpty) return null;

    // Market mood influences event probabilities
    final mood = game.marketMood;
    final r = _random.nextDouble();

    // Bias: high mood → more booms, low mood → more crashes
    if (mood > 0.3 && r < mood * 0.4) {
      final boom = available.where((e) => e.id == 'mining_boom').firstOrNull;
      if (boom != null) return boom;
    }
    if (mood < -0.3 && r < -mood * 0.4) {
      final crash = available.where((e) => e.id == 'market_crash').firstOrNull;
      if (crash != null) return crash;
    }

    return available[_random.nextInt(available.length)];
  }

  static Game _applyEvent(Game game, GameEvent event) {
    var g = game;

    switch (event.id) {
      case 'dust':
        // +15°C to all GPUs (applied via thermal system modifier)
        break; // handled by active event presence in thermal calc
      case 'fan_fail':
        break; // +25°C to one random GPU
      case 'silicon_lottery':
        // Pick random GPU, boost hashrate permanently
        if (g.farm.gpuList.isNotEmpty) {
          final idx = _random.nextInt(g.farm.gpuList.length);
          final gpu = g.farm.gpuList[idx];
          // Boost via overclockLevel +1 permanently
          final newList = [...g.farm.gpuList];
          newList[idx] = gpu.copyWith(
            siliconLotteryLevel: gpu.siliconLotteryLevel + 1,
          );
          g = g.copyWith(farm: g.farm.copyWith(gpuList: newList));
        }
        break;
      case 'gpu_sale':
        break; // -30% shop prices
      case 'market_crash':
        // -40% to weighted random non-immune coin
        {
          final eligible = g.coins.where((c) => !c.eventImmune).toList();
          if (eligible.isNotEmpty) {
            final coin = _weightedPick(eligible, (c) => c.crashChance);
            final idx = g.coins.indexOf(coin);
            event.data = {'coinIdx': idx, 'oldPrice': coin.price};
            final newCoins = [...g.coins];
            newCoins[idx] = coin.copyWith(
              price: (coin.price * 0.6).clamp(0.01, 10000),
            );
            g = g.copyWith(coins: newCoins);
          }
        }
        break;
      case 'mining_boom':
        // +30% to weighted random non-immune coin
        {
          final eligible = g.coins.where((c) => !c.eventImmune).toList();
          if (eligible.isNotEmpty) {
            final coin = _weightedPick(eligible, (c) => c.boomChance);
            final idx = g.coins.indexOf(coin);
            event.data = {'coinIdx': idx, 'oldPrice': coin.price};
            final newCoins = [...g.coins];
            newCoins[idx] = coin.copyWith(
              price: (coin.price * 1.3).clamp(0.01, 10000),
            );
            g = g.copyWith(coins: newCoins);
          }
        }
        break;
      case 'power_surge':
        // Double electricity rate
        g = g.copyWith(electricityRate: g.electricityRate * 2);
        break;
    }

    return g.copyWith(activeEvents: [...g.activeEvents, event]);
  }

  static Game _removeEvent(Game game, GameEvent event) {
    switch (event.id) {
      case 'power_surge':
        return game.copyWith(electricityRate: game.electricityRate / 2);
      case 'market_crash':
      case 'mining_boom':
        // Restore coin price to pre-event level
        final data = event.data;
        if (data != null) {
          final idx = data['coinIdx'] as int;
          final oldPrice = (data['oldPrice'] as num).toDouble();
          if (idx < game.coins.length) {
            final newCoins = [...game.coins];
            newCoins[idx] = game.coins[idx].copyWith(price: oldPrice);
            return game.copyWith(coins: newCoins);
          }
        }
        return game;
      default:
        return game;
    }
  }

  /// Pick a coin weighted by a selector function.
  static T _weightedPick<T>(List<T> items, double Function(T) weightFn) {
    final total = items.fold(0.0, (s, i) => s + weightFn(i).abs());
    if (total <= 0) return items[_random.nextInt(items.length)];
    var r = _random.nextDouble() * total;
    for (final item in items) {
      r -= weightFn(item).abs();
      if (r <= 0) return item;
    }
    return items.last;
  }
}
