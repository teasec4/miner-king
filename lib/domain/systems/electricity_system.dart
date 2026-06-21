import '../catalogs/gpu_catalog.dart';
import '../catalogs/psu_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import 'employee_system.dart';

/// Calculates electricity costs per tick.
class ElectricitySystem {
  ElectricitySystem._();

  /// Calculate electricity cost for one tick and deduct from money.
  static Game update(Game game) {
    final totalWatts = _totalPowerConsumption(game);
    final netWatts = (totalWatts - game.farm.solarPower).clamp(
      0,
      double.infinity,
    );
    var costPerHour = netWatts * game.electricityRate;
    final elecReduction = EmployeeSystem.electricityReduction(game);
    if (elecReduction > 0) costPerHour *= (1 - elecReduction);
    final cost = costPerHour / GameConfig.ticksPerHour;

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
      var power =
          model.basePowerConsumption *
          (1 + gpu.effectiveOverclock * GameConfig.overclockPowerPerLevel);
      final psuIdx = PsuCatalog.indexOf(gpu.equippedPsu ?? 'psu_stock');
      power *= (1 - psuIdx * GameConfig.psuEfficiencyPerTier);
      total += power;
    }
    return total;
  }

  /// Total power draw for display (watts).
  static double totalPowerDraw(Game game) => _totalPowerConsumption(game);

  /// Solar power generated (watts).
  static double solarPower(Game game) => game.farm.solarPower;

  /// Net power after solar offset.
  static double netPowerDraw(Game game) {
    return (_totalPowerConsumption(game) - game.farm.solarPower).clamp(
      0,
      double.infinity,
    );
  }

  /// Cost per hour for display (accounts for solar).
  static double costPerHour(Game game) {
    final netWatts = (_totalPowerConsumption(game) - game.farm.solarPower)
        .clamp(0, double.infinity);
    return netWatts * game.electricityRate;
  }
}
