import '../models/game_event.dart';

/// Static catalog of all possible random events.
class EventCatalog {
  EventCatalog._();

  static final all = [
    GameEvent(
      id: 'dust',
      name: 'Dust Storm',
      description: 'Dust clogs the fans — all GPUs overheat by +15°C.',
      durationTicks: 90,
    ),
    GameEvent(
      id: 'fan_fail',
      name: 'Fan Failure',
      description: 'A fan bearing seized — one random GPU runs +25°C hotter.',
      durationTicks: 60,
    ),
    GameEvent(
      id: 'silicon_lottery',
      name: 'Silicon Lottery',
      description:
          'One of your GPUs was exceptionally binned — permanent +20% hashrate.',
      durationTicks: 0, // instant permanent
    ),
    GameEvent(
      id: 'gpu_sale',
      name: 'GPU Sale',
      description: 'Supplier overstock — all GPU prices reduced by 30%.',
      durationTicks: 120,
    ),
    GameEvent(
      id: 'market_crash',
      name: 'Market Crash',
      description: 'Panic selling! A random coin price drops by 40%.',
      durationTicks: 0,
    ),
    GameEvent(
      id: 'mining_boom',
      name: 'Mining Boom',
      description: 'A random coin surges +30% in price.',
      durationTicks: 0,
    ),
    GameEvent(
      id: 'power_surge',
      name: 'Power Surge',
      description: 'Voltage spike — electricity cost doubled for 60 seconds.',
      durationTicks: 60,
    ),
  ];

  static GameEvent? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
