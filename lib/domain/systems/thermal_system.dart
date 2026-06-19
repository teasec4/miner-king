import '../catalogs/gpu_catalog.dart';
import '../models/game.dart';

/// Calculates GPU temperatures based on model, overclock, cooling, and external factors.
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
      if (gpu.isBroken) return gpu; // broken GPUs don't heat up

      // Base temp from the GPU model's spec
      final model = GpuCatalog.byId(gpu.modelId);
      double temp = model?.baseTemperature ?? 50.0;

      // Overclock adds heat
      temp += gpu.overclockLevel * 20.0;

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
    if (temp < 70) return 'normal';
    if (temp < 90) return 'warning';
    return 'critical';
  }
}
