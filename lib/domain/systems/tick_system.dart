import '../models/game.dart';
import 'electricity_system.dart';
import 'market_system.dart';
import 'mining_system.dart';
import 'thermal_system.dart';
import 'wear_system.dart';

/// Main game loop – advances the simulation by one tick.
class TickSystem {
  TickSystem._();

  static Game tick(Game game) {
    var g = game;

    // 1. Update market (all coins)
    g = MarketSystem.update(g);

    // 2. Mine coins — returns per-coin map
    final mined = MiningSystem.mine(g);
    final newHoldings = Map<String, double>.from(g.holdings);
    for (final entry in mined.entries) {
      newHoldings[entry.key] = (newHoldings[entry.key] ?? 0) + entry.value;
    }
    g = g.copyWith(holdings: newHoldings);

    // 3. Update temperatures
    g = ThermalSystem.update(g);

    // 4. Apply wear from heat
    g = WearSystem.update(g);

    // 5. Deduct electricity cost
    g = ElectricitySystem.update(g);

    // 6. Advance tick
    g = g.copyWith(tick: g.tick + 1);

    return g;
  }
}
