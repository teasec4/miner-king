import '../models/game.dart';
import '../models/player_profile.dart';
import '../catalogs/debuff_catalog.dart';

/// Gradual GPU degradation system.
///
/// Wear starts at 65°C+. Each °C above increases wear rate.
/// Worn cards degrade faster (snowball) and run hotter.
class WearSystem {
  WearSystem._();

  static Game update(Game game) {
    final updatedGpus = game.farm.gpuList.map((gpu) {
      final temp = gpu.temperature;
      if (temp < 65) return gpu; // safe zone
      if (gpu.condition <= 0) return gpu;
      if (!gpu.isPowered) return gpu;

      // Wear rate: gentle at first, dangerous at high temps
      // 0 at 65°C → 0.0005/tick at 90°C → more above
      final wearRate = temp <= 90
          ? (temp - 65) / 25 * 0.0005
          : 0.0005 + (temp - 90) * 0.0005;

      // Worn cards degrade up to 3x faster
      var accelerator = 1 + (1 - gpu.condition) * 2;
      // Debuffs: wear multiplier
      for (final d in gpu.debuffs) {
        final debuff = DebuffCatalog.byId(d);
        if (debuff != null) accelerator *= debuff.wearMul;
      }
      // Perk: Risk Lover +50% wear
      if (game.perks.any((p) => p.effect == PerkEffect.riskLover)) {
        accelerator *= 1.5;
      }

      final newCondition = (gpu.condition - wearRate * accelerator).clamp(
        0.0,
        1.0,
      );

      return gpu.copyWith(condition: newCondition);
    }).toList();

    return game.copyWith(farm: game.farm.copyWith(gpuList: updatedGpus));
  }
}
