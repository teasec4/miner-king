import '../catalogs/debuff_catalog.dart';
import '../catalogs/gpu_catalog.dart';
import '../catalogs/paste_catalog.dart';
import '../catalogs/psu_catalog.dart';
import '../config/game_config.dart';
import '../models/game.dart';
import '../models/player_profile.dart';

/// Calculates GPU temperatures based on model, overclock, cooling, wear, and external factors.
class ThermalSystem {
  ThermalSystem._();

  /// Calculate temperatures for all GPUs and return updated Game.
  static Game update(Game game) {
    final updatedGpus = game.farm.gpuList.map((gpu) {
      if (gpu.condition <= 0) {
        return gpu.copyWith(temperature: GameConfig.ambientTemperature);
      }
      if (!gpu.isPowered) {
        return gpu.copyWith(temperature: GameConfig.ambientTemperature);
      }

      // Cooling: per-GPU equipped cooling overrides farm default
      final gpuCooling = gpu.equippedCooling ?? game.farm.coolingSystem;
      final cooling = GameConfig.coolingPower[gpuCooling] ?? 0.0;

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

      // Overclock adds heat — PSU quality reduces OC heat
      final psuIdx = PsuCatalog.indexOf(gpu.equippedPsu ?? 'psu_stock');
      temp +=
          gpu.effectiveOverclock *
          (GameConfig.overclockBaseHeat -
                  psuIdx * GameConfig.psuHeatReductionPerTier)
              .clamp(GameConfig.overclockMinHeat, GameConfig.overclockBaseHeat);

      // Worn cards run hotter
      temp += (1 - gpu.condition) * GameConfig.wearHeatFactor;

      // Debuffs temperature
      for (final d in gpu.debuffs) {
        final debuff = DebuffCatalog.byId(d);
        if (debuff != null) temp += debuff.tempAdd;
      }

      // Cooling reduces heat
      temp += cooling;

      // Thermal paste
      if (gpu.equippedPaste != null) {
        final paste = PasteCatalog.byId(gpu.equippedPaste!);
        if (paste != null) temp += paste.tempReduction;
      }

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
