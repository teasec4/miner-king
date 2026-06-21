import 'dart:math';
import '../catalogs/event_catalog.dart';
import '../config/game_config.dart';
import '../events/game_events.dart';
import '../models/game.dart';
import 'employee_system.dart';

/// Interface for random event triggering and lifecycle.
abstract class EventSystem {
  (Game, GameEvent?) update(Game game);
}

class DefaultEventSystem implements EventSystem {
  final Random _random;
  int _nextEventIn;

  DefaultEventSystem({Random? random})
    : _random = random ?? Random(),
      _nextEventIn = GameConfig.initialEventDelay;

  @override
  (Game, GameEvent?) update(Game game) {
    var g = game;
    GameEvent? triggered;

    final durationReduction = EmployeeSystem.eventDurationReduction(g);

    // ── Tick active events ──
    final updatedEvents = <GameEvent>[];
    for (final e in game.activeEvents) {
      g = e.onTick(g);

      if (e.isInstant) {
        final remaining = e.remainingTicks - 1;
        if (remaining <= -GameConfig.instantEventCleanupDelay) continue;
        updatedEvents.add(e.withRemaining(remaining));
      } else {
        final decay = GameConfig.securityTickDecay + durationReduction;
        final remaining = (e.remainingTicks - decay).ceil();
        if (remaining <= 0) {
          g = e.onRemove(g);
        } else {
          updatedEvents.add(e.withRemaining(remaining));
        }
      }
    }
    g = g.copyWith(activeEvents: updatedEvents);

    // ── Pending event warning countdown ──
    if (g.pendingEvent != null) {
      final left = g.pendingEventTicksLeft - 1;
      if (left <= 0) {
        // Fire the pending event
        final evt = g.pendingEvent!;
        g = evt.onApply(g);

        // Check combos: new event vs each already-active event
        for (final active in g.activeEvents) {
          g = evt.onCombo(g, active);
          g = active.onCombo(g, evt);
        }

        final unseen = Map<String, int>.from(g.unseenEvents);
        unseen[evt.category] = (unseen[evt.category] ?? 0) + 1;
        g = g.copyWith(
          activeEvents: [...g.activeEvents, evt],
          unseenEvents: unseen,
          pendingEvent: null,
          pendingEventTicksLeft: 0,
        );
        triggered = evt;
      } else {
        g = g.copyWith(pendingEventTicksLeft: left);
      }
    }

    // ── Trigger new pending event? ──
    if (g.pendingEvent == null) {
      _nextEventIn--;
      if (_nextEventIn <= 0) {
        _nextEventIn =
            GameConfig.minEventInterval +
            _random.nextInt(
              GameConfig.maxEventInterval - GameConfig.minEventInterval,
            );
        if (g.activeEvents.length < GameConfig.maxActiveEvents) {
          final event = _pickRandomEvent(g);
          if (event != null) {
            g = g.copyWith(
              pendingEvent: event,
              pendingEventTicksLeft: GameConfig.eventWarningTicks,
            );
          }
        }
      }
    }

    return (g, triggered);
  }

  GameEvent? _pickRandomEvent(Game game) {
    final securityReduction = EmployeeSystem.eventChanceReduction(game);

    final cats = ['rig', 'market', 'city'];
    var cat = cats[_random.nextInt(cats.length)];
    if (cat == 'rig' &&
        securityReduction > 0 &&
        _random.nextDouble() < securityReduction) {
      cat = cats[_random.nextInt(cats.length)];
    }

    var pool = _eventPool(cat, game);

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

  /// Builds the pool of available event templates for a category.
  /// Coin-price events and FreePower are created with actual game data.
  List<GameEvent> _eventPool(String cat, Game game) {
    final existingIds = game.activeEvents.map((e) => e.id).toSet();

    switch (cat) {
      case 'rig':
        return EventCatalog.rigEvents
            .where((e) => !existingIds.contains(e.id))
            .toList();

      case 'market':
        final pool = <GameEvent>[];
        if (!existingIds.contains('gpu_sale')) {
          pool.add(const GpuSaleEvent());
        }
        // Coin-price events need a random eligible coin
        final eligible = game.coins.where((c) => !c.eventImmune).toList();
        if (eligible.isNotEmpty) {
          if (!existingIds.contains('market_crash')) {
            final coin = _weightedPick(eligible, (c) => c.crashChance);
            pool.add(
              MarketCrashEvent(
                coinIdx: game.coins.indexOf(coin),
                oldPrice: coin.price,
              ),
            );
          }
          if (!existingIds.contains('mining_boom')) {
            final coin = _weightedPick(eligible, (c) => c.boomChance);
            pool.add(
              MiningBoomEvent(
                coinIdx: game.coins.indexOf(coin),
                oldPrice: coin.price,
              ),
            );
          }
          if (!existingIds.contains('fomo_rally')) {
            final coin = _weightedPick(eligible, (c) => c.boomChance);
            pool.add(
              FomoRallyEvent(
                coinIdx: game.coins.indexOf(coin),
                oldPrice: coin.price,
              ),
            );
          }
        }
        return pool;

      case 'city':
        final pool = <GameEvent>[];
        if (!existingIds.contains('tax_break')) {
          pool.add(const TaxBreakEvent());
        }
        if (!existingIds.contains('job_fair')) {
          pool.add(const JobFairEvent());
        }
        if (!existingIds.contains('rent_hike')) {
          pool.add(const RentHikeEvent());
        }
        if (!existingIds.contains('free_power')) {
          pool.add(FreePowerEvent(oldRate: game.electricityRate));
        }
        return pool;

      default:
        return [];
    }
  }

  T _weightedPick<T>(List<T> items, double Function(T) weightFn) {
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
