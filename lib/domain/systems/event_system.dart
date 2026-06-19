import 'dart:math';
import '../catalogs/event_catalog.dart';
import '../models/game.dart';
import '../models/game_event.dart';

/// Triggers random events and manages active event durations.
class EventSystem {
  EventSystem._();
  static final _random = Random();
  static int _nextEventIn = 180;

  static (Game, GameEvent?) update(Game game) {
    var g = game;
    GameEvent? triggered;

    // ── Tick active events ──
    final updatedEvents = <GameEvent>[];
    for (final e in game.activeEvents) {
      if (e.isInstant) {
        final remaining = e.remainingTicks - 1;
        if (remaining <= -60) continue;
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
      _nextEventIn = 60 + _random.nextInt(240);
      if (g.activeEvents.length < 3) {
        final event = _pickRandomEvent(g);
        if (event != null) {
          g = _applyEvent(g, event);
          // Mark as unseen in the event's category
          final unseen = Map<String, int>.from(g.unseenEvents);
          unseen[event.category] = (unseen[event.category] ?? 0) + 1;
          g = g.copyWith(unseenEvents: unseen);
          triggered = event;
        }
      }
    }

    return (g, triggered);
  }

  static GameEvent? _pickRandomEvent(Game game) {
    // Pick from a random category, weighted
    final cats = ['rig', 'market', 'city'];
    final cat = cats[_random.nextInt(cats.length)];
    var pool = switch (cat) {
      'rig' => EventCatalog.rigEvents,
      'market' => EventCatalog.marketEvents,
      _ => EventCatalog.cityEvents,
    };
    pool = pool
        .where((e) => !game.activeEvents.any((a) => a.id == e.id))
        .toList();
    if (pool.isEmpty) return null;

    final mood = game.marketMood;
    final r = _random.nextDouble();
    if (mood > 0.3 && r < mood * 0.4) {
      final boom = pool.where((e) => e.id == 'mining_boom').firstOrNull;
      if (boom != null) return boom;
    }
    if (mood < -0.3 && r < -mood * 0.4) {
      final crash = pool.where((e) => e.id == 'market_crash').firstOrNull;
      if (crash != null) return crash;
    }
    return pool[_random.nextInt(pool.length)];
  }

  static Game _applyEvent(Game game, GameEvent event) {
    var g = game;
    switch (event.id) {
      case 'dust':
      case 'fan_fail':
        break; // handled by thermal system
      case 'silicon_lottery':
        if (g.farm.gpuList.isNotEmpty) {
          final idx = _random.nextInt(g.farm.gpuList.length);
          final gpu = g.farm.gpuList[idx];
          final newList = [...g.farm.gpuList];
          newList[idx] = gpu.copyWith(
            siliconLotteryLevel: gpu.siliconLotteryLevel + 1,
          );
          g = g.copyWith(farm: g.farm.copyWith(gpuList: newList));
        }
        break;
      case 'gpu_sale':
        break;
      case 'market_crash':
        {
          final eligible = g.coins.where((c) => !c.eventImmune).toList();
          if (eligible.isNotEmpty) {
            final coin = _weightedPick(eligible, (c) => c.crashChance);
            final idx = g.coins.indexOf(coin);
            event.data = {'coinIdx': idx, 'oldPrice': coin.price};
            final newCoins = [...g.coins];
            newCoins[idx] = coin.copyWith(
              price: (coin.price * 0.6).clamp(0.01, 999999),
            );
            g = g.copyWith(coins: newCoins);
          }
        }
        break;
      case 'mining_boom':
        {
          final eligible = g.coins.where((c) => !c.eventImmune).toList();
          if (eligible.isNotEmpty) {
            final coin = _weightedPick(eligible, (c) => c.boomChance);
            final idx = g.coins.indexOf(coin);
            event.data = {'coinIdx': idx, 'oldPrice': coin.price};
            final newCoins = [...g.coins];
            newCoins[idx] = coin.copyWith(
              price: (coin.price * 1.3).clamp(0.01, 999999),
            );
            g = g.copyWith(coins: newCoins);
          }
        }
        break;
      case 'power_surge':
        g = g.copyWith(electricityRate: g.electricityRate * 2);
        break;
      case 'tax_break':
        g = g.copyWith(electricityRate: g.electricityRate * 0.5);
        break;
      case 'rent_hike':
        // Applied in EmployeeSystem via active event check
        break;
      case 'job_fair':
        // Applied in JobSystem via active event check
        break;
    }
    return g.copyWith(activeEvents: [...g.activeEvents, event]);
  }

  static Game _removeEvent(Game game, GameEvent event) {
    switch (event.id) {
      case 'power_surge':
        return game.copyWith(electricityRate: game.electricityRate / 2);
      case 'tax_break':
        return game.copyWith(electricityRate: game.electricityRate / 0.5);
      case 'market_crash':
      case 'mining_boom':
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
