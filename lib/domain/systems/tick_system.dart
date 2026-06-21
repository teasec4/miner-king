import '../models/game.dart';
import '../models/gpu_instance.dart';
import '../events/game_events.dart';
import '../catalogs/gpu_catalog.dart';
import 'course_system.dart';
import 'credit_system.dart';
import 'electricity_system.dart';
import 'employee_system.dart';
import 'job_system.dart';
import 'mining_system.dart';
import 'systems.dart';
import 'thermal_system.dart';

/// Main game loop — advances the simulation by one tick.
///
/// Receives [Systems] via DI so stateful systems (Market, Event, Wear)
/// can be mocked in tests.
class TickSystem {
  final Systems _sys;

  TickSystem(this._sys);

  (Game, GameEvent?) tick(Game game) {
    var g = game;
    GameEvent? newEvent;

    // 1. Update market (all coins)
    g = _sys.market.update(g);

    // 2. Process events (tick active, maybe trigger new)
    (g, newEvent) = _sys.event.update(g);

    // 3. Mine coins (cycle-based)
    final (updatedGpus, mined) = MiningSystem.mine(g);
    final newHoldings = Map<String, double>.from(g.holdings);
    for (final entry in mined.entries) {
      newHoldings[entry.key] = (newHoldings[entry.key] ?? 0) + entry.value;
    }
    g = g.copyWith(
      holdings: newHoldings,
      farm: g.farm.copyWith(gpuList: updatedGpus),
    );

    // 4. Update temperatures
    g = ThermalSystem.update(g);

    // 5. Apply wear from heat
    g = _sys.wear.update(g);

    // 5b. Remove dead GPUs (condition <= 0 = destroyed)
    final aliveGpus = <GpuInstance>[];
    String? destroyedModel;
    for (final gpu in g.farm.gpuList) {
      if (gpu.condition <= 0) {
        final model = GpuCatalog.byId(gpu.modelId);
        destroyedModel = model?.name ?? gpu.modelId;
      } else {
        aliveGpus.add(gpu);
      }
    }
    if (aliveGpus.length < g.farm.gpuList.length) {
      g = g.copyWith(
        farm: g.farm.copyWith(gpuList: aliveGpus),
        destroyedGpu: destroyedModel,
      );
    }

    // 6. Deduct electricity cost
    g = ElectricitySystem.update(g);

    // 7. Apply loan interest + risk
    g = CreditSystem.update(g);

    // 8. Pay job salary + gain exp
    g = JobSystem.update(g);

    // 9. Tick course progress
    g = CourseSystem.update(g);

    // 10. Process employees + office
    g = EmployeeSystem.update(g);

    // 11. Advance tick
    g = g.copyWith(tick: g.tick + 1);

    // 14. Check game-over conditions
    if (!g.gameOver) {
      g = _checkGameOver(g);
    }

    return (g, newEvent);
  }

  /// Check loss conditions: bankruptcy, all GPUs dead, debt spiral.
  Game _checkGameOver(Game game) {
    // All GPUs destroyed
    if (game.farm.gpuList.isEmpty) {
      return game.copyWith(
        gameOver: true,
        gameOverReason: 'All GPUs destroyed. Farm is gone.',
      );
    }

    // Bankruptcy: debt far exceeds money
    if (game.money < -5000) {
      return game.copyWith(
        gameOver: true,
        gameOverReason: 'Bankrupt! Debt collectors took everything.',
      );
    }

    // Debt spiral: total debt > 3x net worth (assets + money)
    final totalDebt = CreditSystem.totalDebt(game);
    if (totalDebt > 0) {
      var netWorth = game.money;
      for (final coin in game.coins) {
        final holding = game.holdings[coin.id] ?? 0;
        netWorth += holding * coin.price;
      }
      // Rough GPU value
      for (final gpu in game.farm.gpuList) {
        final model = GpuCatalog.byId(gpu.modelId);
        if (model != null) {
          netWorth += model.price * gpu.condition;
        }
      }
      netWorth -= totalDebt;
      if (netWorth < 0 && totalDebt > game.money.abs() * 3) {
        return game.copyWith(
          gameOver: true,
          gameOverReason: 'Debt spiral! Loans exceeded all assets.',
        );
      }
    }

    return game;
  }
}
