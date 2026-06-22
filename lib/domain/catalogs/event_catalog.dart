import '../events/game_events.dart';

/// Static catalog of all possible random events, split by category.
class EventCatalog {
  EventCatalog._();

  static final rigEvents = [
    const DustStormEvent(),
    const FanFailureEvent(),
    const OverheatEvent(),
    const PowerSurgeEvent(),
  ];

  static final marketEvents = [
    const GpuSaleEvent(),
    // Coin-price events need coinIdx+oldPrice at creation time
    // (set by EventSystem when picking)
  ];

  static final cityEvents = [
    const TaxBreakEvent(),
    const JobFairEvent(),
    const RentHikeEvent(),
    // FreePowerEvent needs oldRate at creation time
  ];

  static final all = [...rigEvents, ...marketEvents, ...cityEvents];

  static GameEvent? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
