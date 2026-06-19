import '../models/game.dart';
import 'electricity_system.dart';
import 'market_system.dart';
import 'mining_system.dart';
import 'thermal_system.dart';
import 'wear_system.dart';

/// Main game loop – advances the simulation by one tick.
/// Orchestrates all systems in order.
class TickSystem {
  TickSystem._();

  static Game tick(Game game) {
    var g = game;

    // 1. Update market (price + phase)
    g = MarketSystem.update(g);

    // 2. Mine coins based on current hashrate
    final coinsMined = MiningSystem.mine(g);
    g = g.copyWith(coins: g.coins + coinsMined);

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
