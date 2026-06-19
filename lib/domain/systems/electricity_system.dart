import '../catalogs/gpu_catalog.dart';
import '../models/game.dart';

/// Calculates electricity costs per tick.
///
/// Uses a game-friendly formula: hourly cost = totalWatts × electricityRate.
/// electricityRate is a game coefficient (not real $/kWh).
/// Example: 120W × $0.12 = $14.40/h.
class ElectricitySystem {
  ElectricitySystem._();

  /// Calculate electricity cost for one tick and deduct from money.
  static Game update(Game game) {
    final totalWatts = _totalPowerConsumption(game);
    // Hourly cost = watts * rate (game formula)
    final costPerHour = totalWatts * game.electricityRate;
    // Per tick (1 second)
    final cost = costPerHour / 3600.0;

    final newMoney = ((game.money - cost).clamp(0, double.infinity) as double);
    return game.copyWith(money: newMoney);
  }

  /// Total power consumption of all GPUs (watts), including overclock penalty.
  static double _totalPowerConsumption(Game game) {
    double total = 0;
    for (final gpu in game.farm.gpuList) {
      if (gpu.condition <= 0) continue;
      if (!gpu.isPowered) continue;
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
    return _totalPowerConsumption(game) * game.electricityRate;
  }
}
