import '../catalogs/gpu_catalog.dart';
import '../models/game.dart';

/// Calculates electricity costs per tick.
class ElectricitySystem {
  ElectricitySystem._();

  /// Default electricity rate in $/kWh.
  static const double defaultRate = 0.12;

  /// Calculate electricity cost for one tick and deduct from money.
  /// Returns updated Game, or same Game if money would go negative
  /// (player can't go bankrupt from electricity alone in v0.2).
  static Game update(Game game) {
    final totalWatts = _totalPowerConsumption(game);
    // kWh per tick (1 second): watts / 1000 / 3600
    final kWhPerTick = totalWatts / 1000.0 / 3600.0;
    final cost = kWhPerTick * game.electricityRate;

    // Don't go below zero from electricity
    final newMoney = ((game.money - cost).clamp(0, double.infinity) as double);

    return game.copyWith(money: newMoney);
  }

  /// Total power consumption of all GPUs (watts), including overclock penalty.
  static double _totalPowerConsumption(Game game) {
    double total = 0;
    for (final gpu in game.farm.gpuList) {
      if (gpu.isBroken) continue;
      final model = GpuCatalog.byId(gpu.modelId);
      if (model == null) continue;
      // Overclock adds 10% power per level
      total += model.basePowerConsumption * (1 + gpu.overclockLevel * 0.1);
    }
    return total;
  }

  /// Total power draw for display (watts).
  static double totalPowerDraw(Game game) => _totalPowerConsumption(game);

  /// Cost per hour for display.
  static double costPerHour(Game game) {
    final watts = _totalPowerConsumption(game);
    return watts / 1000.0 * game.electricityRate;
  }

  /// Cost per minute for display.
  static double costPerMinute(Game game) {
    final watts = _totalPowerConsumption(game);
    return watts / 1000.0 / 60.0 * game.electricityRate;
  }
}
