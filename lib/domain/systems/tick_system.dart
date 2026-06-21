import '../models/game.dart';
import '../events/game_events.dart';
import 'course_system.dart';
import 'credit_system.dart';
import 'electricity_system.dart';
import 'employee_system.dart';
import 'investment_system.dart';
import 'job_system.dart';
import 'mining_system.dart';
import 'property_system.dart';
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

    // 11. Process investments
    g = InvestmentSystem.update(g);

    // 12. Collect property rent
    g = PropertySystem.update(g);

    // 13. Advance tick
    g = g.copyWith(tick: g.tick + 1);

    return (g, newEvent);
  }
}
