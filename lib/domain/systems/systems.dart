import 'event_system.dart';
import 'market_system.dart';
import 'wear_system.dart';

/// DI container for stateful game systems.
///
/// Stateful systems (those with internal Random state) are injected
/// so they can be mocked in tests with fixed seeds.
/// Pure-function systems (MiningSystem, ThermalSystem, etc.)
/// remain static since they're naturally testable.
class Systems {
  final MarketSystem market;
  final EventSystem event;
  final WearSystem wear;

  Systems({MarketSystem? market, EventSystem? event, WearSystem? wear})
    : market = market ?? DefaultMarketSystem(),
      event = event ?? DefaultEventSystem(),
      wear = wear ?? DefaultWearSystem();
}
