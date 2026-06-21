import '../catalogs/gpu_catalog.dart';
import '../catalogs/psu_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/specialization.dart';
import 'employee_system.dart';
import 'job_system.dart';

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

    // Career Climber: -30% electricity
    if (game.specialization == Specialization.careerClimber) {
      costPerHour *= (1 - GameConfig.climberElectricityDiscount);
    }

    // Tech & IT Lv3 job perk
    final jobDiscount = JobSystem.electricityDiscount(game);
    if (jobDiscount > 0) costPerHour *= (1 - jobDiscount);

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

  /// PSU efficiency multiplier (1.0 = no overload, < 1.0 = penalty).
  /// If total GPU wattage exceeds PSU capacity, hashrate is reduced.
  static double psuEfficiency(Game game) {
    final totalWatt = _totalPowerConsumption(game);
    if (totalWatt <= 0) return 1.0;
    final capacity = PsuCatalog.capacity(game.farm.psuTier);
    if (totalWatt <= capacity) return 1.0;
    return (capacity / totalWatt).clamp(0.3, 1.0);
  }

  /// Cost per hour for display (accounts for solar).
  static double costPerHour(Game game) {
    final netWatts = (_totalPowerConsumption(game) - game.farm.solarPower)
        .clamp(0, double.infinity);
    return netWatts * game.electricityRate;
  }
}
