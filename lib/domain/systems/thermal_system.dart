import '../catalogs/debuff_catalog.dart';
import '../catalogs/gpu_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/player_profile.dart';

/// Calculates GPU temperatures based on model, overclock, farm cooling, wear, and external factors.
class ThermalSystem {
  ThermalSystem._();

  /// Calculate temperatures for all GPUs and return updated Game.
  static Game update(Game game) {
    final cooling = GameConfig.coolingPower[game.farm.coolingSystem] ?? 0.0;

    final updatedGpus = game.farm.gpuList.map((gpu) {
      if (gpu.condition <= 0 || !gpu.isPowered) {
        return gpu.copyWith(temperature: GameConfig.ambientTemperature);
      }

      // Base temp from the GPU model's spec
      final model = GpuCatalog.byId(gpu.modelId);
      double temp = model?.baseTemperature ?? GameConfig.dangerousTemp - 40;

      // Event: Dust Storm
      if (game.activeEvents.any((e) => e.id == 'dust')) {
        temp += GameConfig.dustStormTempBonus;
      }
      // Event: Fan Failure — +25°C to first alive GPU
      if (game.activeEvents.any((e) => e.id == 'fan_fail')) {
        final firstAlive = game.farm.gpuList
            .where((g) => g.condition > 0 && g.isPowered)
            .firstOrNull;
        if (firstAlive != null && gpu.id == firstAlive.id) {
          temp += GameConfig.fanFailTempBonus;
        }
      }

      // Perk: Efficient Fans
      if (game.perks.any((p) => p.effect == PerkEffect.efficientFans)) {
        temp -= GameConfig.efficientFansTempReduction;
      }

      // Overclock adds heat
      temp += gpu.effectiveOverclock * GameConfig.overclockBaseHeat;

      // Worn cards run hotter
      temp += (1 - gpu.condition) * GameConfig.wearHeatFactor;

      // Debuffs temperature
      for (final d in gpu.debuffs) {
        final debuff = DebuffCatalog.byId(d);
        if (debuff != null) temp += debuff.tempAdd;
      }

      // Farm cooling reduces heat
      temp += cooling;

      temp = temp.clamp(GameConfig.minTemperature, GameConfig.maxTemperature);

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
