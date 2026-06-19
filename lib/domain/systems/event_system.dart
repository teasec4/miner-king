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
      if (e.isInstant) continue; // already applied, stays forever
      final remaining = e.remainingTicks - 1;
      if (remaining <= 0) {
        g = _removeEvent(g, e);
      } else {
        updatedEvents.add(e.copyWith(remainingTicks: remaining));
      }
    }
    // Keep instant events
    for (final e in game.activeEvents.where((e) => e.isInstant)) {
      updatedEvents.add(e);
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
    final available = EventCatalog.all
        .where((e) => !game.activeEvents.any((a) => a.id == e.id))
        .toList();
    if (available.isEmpty) return null;
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
          newList[idx] = gpu.copyWith(overclockLevel: gpu.overclockLevel + 1);
          g = g.copyWith(farm: g.farm.copyWith(gpuList: newList));
        }
        break;
      case 'gpu_sale':
        break; // -30% shop prices
      case 'market_crash':
        // -40% to random coin
        if (g.coins.isNotEmpty) {
          final idx = _random.nextInt(g.coins.length);
          final coin = g.coins[idx];
          final newCoins = [...g.coins];
          newCoins[idx] = coin.copyWith(
            price: (coin.price * 0.6).clamp(0.01, 10000),
          );
          g = g.copyWith(coins: newCoins);
        }
        break;
      case 'mining_boom':
        // +30% to random coin
        if (g.coins.isNotEmpty) {
          final idx = _random.nextInt(g.coins.length);
          final coin = g.coins[idx];
          final newCoins = [...g.coins];
          newCoins[idx] = coin.copyWith(
            price: (coin.price * 1.3).clamp(0.01, 10000),
          );
          g = g.copyWith(coins: newCoins);
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
        // Restore electricity rate
        return game.copyWith(electricityRate: game.electricityRate / 2);
      default:
        return game;
    }
  }
}
