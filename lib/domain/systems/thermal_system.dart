import '../catalogs/gpu_catalog.dart';
import '../models/game.dart';
import '../models/player_profile.dart';

/// Calculates GPU temperatures based on model, overclock, cooling, wear, and external factors.
class ThermalSystem {
  ThermalSystem._();

  /// Cooling efficiency by system type (°C reduction).
  static const _coolingPower = {
    'basic': 0.0,
    'fans': -10.0,
    'water': -20.0,
    'immersion': -30.0,
  };

  /// Calculate temperatures for all GPUs and return updated Game.
  static Game update(Game game) {
    final cooling = _coolingPower[game.farm.coolingSystem] ?? 0.0;

    final updatedGpus = game.farm.gpuList.map((gpu) {
      if (gpu.condition <= 0) {
        return gpu.copyWith(temperature: 25); // dead card, ambient
      }
      if (!gpu.isPowered) {
        return gpu.copyWith(temperature: 25); // turned off
      }

      // Base temp from the GPU model's spec
      final model = GpuCatalog.byId(gpu.modelId);
      double temp = model?.baseTemperature ?? 50.0;

      // Event: Dust Storm — +15°C to all
      if (game.activeEvents.any((e) => e.id == 'dust')) {
        temp += 15;
      }
      // Event: Fan Failure — +25°C to one GPU (first non-dead)
      if (game.activeEvents.any((e) => e.id == 'fan_fail')) {
        final firstAlive = game.farm.gpuList
            .where((g) => g.condition > 0 && g.isPowered)
            .firstOrNull;
        if (firstAlive != null && gpu.id == firstAlive.id) {
          temp += 25;
        }
      }

      // Perk: Efficient Fans -15°C
      if (game.perks.any((p) => p.effect == PerkEffect.efficientFans)) {
        temp -= 15;
      }

      // Overclock adds heat
      temp += gpu.effectiveOverclock * 25.0;

      // Worn cards run hotter: up to +20°C when near death
      temp += (1 - gpu.condition) * 20.0;

      // Cooling reduces heat
      temp += cooling;

      // Clamp to reasonable range
      temp = temp.clamp(20.0, 150.0);

      return gpu.copyWith(temperature: temp);
    }).toList();

    return game.copyWith(farm: game.farm.copyWith(gpuList: updatedGpus));
  }

  /// Returns a temperature status string for display.
  static String status(double temp) {
    if (temp < 65) return 'normal';
    if (temp < 90) return 'warning';
    return 'critical';
  }
}
