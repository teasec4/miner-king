import '../models/game_event.dart';

/// Static catalog of all possible random events, split by category.
class EventCatalog {
  EventCatalog._();

  // ── Rig events (shown on Rig tab) ──

  static final rigDust = GameEvent(
    id: 'dust',
    name: 'Dust Storm',
    description: 'Dust clogs the fans — all GPUs overheat by +15°C.',
    category: 'rig',
    durationTicks: 90,
  );
  static final rigFanFail = GameEvent(
    id: 'fan_fail',
    name: 'Fan Failure',
    description: 'A fan bearing seized — one GPU runs +25°C hotter.',
    category: 'rig',
    durationTicks: 60,
  );
  static final rigOverheat = GameEvent(
    id: 'overheat',
    name: 'Overheat',
    description: 'All GPUs take -5% condition damage instantly.',
    category: 'rig',
    durationTicks: 0,
  );
  static final rigPowerSurge = GameEvent(
    id: 'power_surge',
    name: 'Power Surge',
    description: 'Voltage spike — electricity cost doubled for 60s.',
    category: 'rig',
    durationTicks: 60,
  );

  // ── Market events (shown on Market tab) ──

  static final marketCrash = GameEvent(
    id: 'market_crash',
    name: 'Market Crash',
    description: 'Panic selling! A random coin price drops by 40%.',
    category: 'market',
    durationTicks: 120,
  );
  static final marketBoom = GameEvent(
    id: 'mining_boom',
    name: 'Mining Boom',
    description: 'A random coin surges +30% in price.',
    category: 'market',
    durationTicks: 120,
  );
  static final marketGpuSale = GameEvent(
    id: 'gpu_sale',
    name: 'GPU Sale',
    description: 'Supplier overstock — GPU prices reduced by 30%.',
    category: 'market',
    durationTicks: 120,
  );
  static final marketFomo = GameEvent(
    id: 'fomo_rally',
    name: 'FOMO Rally',
    description: 'Everyone is buying! A random coin +50% for 90s.',
    category: 'market',
    durationTicks: 90,
  );

  // ── City events (shown on City tab) ──

  static final cityTaxBreak = GameEvent(
    id: 'tax_break',
    name: 'Tax Break',
    description: 'Government incentive — electricity cost -50% for 120s.',
    category: 'city',
    durationTicks: 120,
  );
  static final cityJobFair = GameEvent(
    id: 'job_fair',
    name: 'Job Fair',
    description: 'All jobs pay double salary for 90s!',
    category: 'city',
    durationTicks: 90,
  );
  static final cityRentHike = GameEvent(
    id: 'rent_hike',
    name: 'Rent Hike',
    description: 'Landlord raised rent — office rent doubled for 120s.',
    category: 'city',
    durationTicks: 120,
  );
  static final cityFreePower = GameEvent(
    id: 'free_power',
    name: 'Free Power',
    description: 'Grid surplus — electricity cost \$0 for 60s!',
    category: 'city',
    durationTicks: 60,
  );

  static final rigEvents = [rigDust, rigFanFail, rigOverheat, rigPowerSurge];
  static final marketEvents = [
    marketCrash,
    marketBoom,
    marketGpuSale,
    marketFomo,
  ];
  static final cityEvents = [
    cityTaxBreak,
    cityJobFair,
    cityRentHike,
    cityFreePower,
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
