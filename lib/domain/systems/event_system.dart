import 'dart:math';
import '../catalogs/event_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/game_event.dart';
import 'employee_system.dart';

/// Triggers random events and manages active event durations.
class EventSystem {
  EventSystem._();
  static final _random = Random();
  static int _nextEventIn = GameConfig.initialEventDelay;

  static (Game, GameEvent?) update(Game game) {
    var g = game;
    GameEvent? triggered;

    final durationReduction = EmployeeSystem.eventDurationReduction(g);

    // ── Tick active events ──
    final updatedEvents = <GameEvent>[];
    for (final e in game.activeEvents) {
      if (e.isInstant) {
        final remaining = e.remainingTicks - 1;
        if (remaining <= -GameConfig.instantEventCleanupDelay) continue;
        updatedEvents.add(e.copyWith(remainingTicks: remaining));
      } else {
        final decay = GameConfig.securityTickDecay + durationReduction;
        final remaining = (e.remainingTicks - decay).ceil();
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
      _nextEventIn =
          GameConfig.minEventInterval +
          _random.nextInt(
            GameConfig.maxEventInterval - GameConfig.minEventInterval,
          );
      if (g.activeEvents.length < GameConfig.maxActiveEvents) {
        final securityReduction = EmployeeSystem.eventChanceReduction(g);
        final event = _pickRandomEvent(g, securityReduction);
        if (event != null) {
          g = _applyEvent(g, event);
          final unseen = Map<String, int>.from(g.unseenEvents);
          unseen[event.category] = (unseen[event.category] ?? 0) + 1;
          g = g.copyWith(unseenEvents: unseen);
          triggered = event;
        }
      }
    }

    return (g, triggered);
  }

  static GameEvent? _pickRandomEvent(Game game, double securityReduction) {
    // Pick from a random category, weighted
    // Security reduces chance of picking 'rig' category
    final cats = ['rig', 'market', 'city'];
    var cat = cats[_random.nextInt(cats.length)];
    // If security is active and we rolled 'rig', chance to reroll
    if (cat == 'rig' &&
        securityReduction > 0 &&
        _random.nextDouble() < securityReduction) {
      cat = cats[_random.nextInt(cats.length)]; // reroll once
    }
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
      final boom = pool
          .where((e) => e.id == 'mining_boom' || e.id == 'fomo_rally')
          .firstOrNull;
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
      case 'overheat':
        // -5% condition to all GPUs
        {
          final newList = g.farm.gpuList.map((gpu) {
            return gpu.copyWith(
              condition: (gpu.condition - 0.05).clamp(0.0, 1.0),
            );
          }).toList();
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
      case 'fomo_rally':
        {
          final eligible = g.coins.where((c) => !c.eventImmune).toList();
          if (eligible.isNotEmpty) {
            final coin = _weightedPick(eligible, (c) => c.boomChance);
            final idx = g.coins.indexOf(coin);
            event.data = {'coinIdx': idx, 'oldPrice': coin.price};
            final newCoins = [...g.coins];
            newCoins[idx] = coin.copyWith(
              price: (coin.price * 1.5).clamp(0.01, 999999),
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
        break;
      case 'free_power':
        // Electricity -> 0. Store old rate to restore
        event.data = {'oldRate': g.electricityRate};
        g = g.copyWith(electricityRate: 0);
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
      case 'free_power':
        final data = event.data;
        if (data != null && data['oldRate'] != null) {
          return game.copyWith(
            electricityRate: (data['oldRate'] as num).toDouble(),
          );
        }
        return game;
      case 'market_crash':
      case 'mining_boom':
      case 'fomo_rally':
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
